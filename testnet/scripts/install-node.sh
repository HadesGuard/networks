#!/bin/bash

# Install and setup Republic AI node

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

install_node() {
    print_header "Install/Setup Node"
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    if ! check_command curl; then
        read -p "Press Enter to continue..."
        return 1
    fi
    if ! check_command jq; then
        read -p "Press Enter to continue..."
        return 1
    fi
    print_info "Prerequisites check passed!"
    echo ""
    
    # Get moniker
    read -p "Enter your node moniker (name): " MONIKER
    if [ -z "$MONIKER" ]; then
        print_error "Moniker cannot be empty!"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Choose sync mode
    echo ""
    print_info "Choose sync mode:"
    echo "1) State Sync (Recommended - faster)"
    echo "2) Full Sync from Genesis"
    read -p "Enter choice [1-2] (default: 1): " SYNC_MODE
    SYNC_MODE=${SYNC_MODE:-1}
    
    if [ "$SYNC_MODE" != "1" ] && [ "$SYNC_MODE" != "2" ]; then
        print_error "Invalid choice!"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Detect architecture
    ARCH=$(detect_arch)
    BINARY_URL_ARCH="$BINARY_URL"
    if [ "$ARCH" = "arm64" ]; then
        BINARY_URL_ARCH="https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-arm64"
    fi
    print_info "Detected architecture: $ARCH"
    echo ""
    
    # Install binary (Linux only)
    if [[ "$IS_MAC" == false ]]; then
        print_info "Installing republicd binary..."
        if [ -f "/usr/local/bin/republicd" ]; then
            print_warn "republicd already exists at /usr/local/bin/republicd"
            read -p "Do you want to overwrite it? [y/N]: " OVERWRITE
            if [[ "$OVERWRITE" =~ ^[Yy]$ ]]; then
                curl -L "$BINARY_URL_ARCH" -o /tmp/republicd
                chmod +x /tmp/republicd
                sudo mv /tmp/republicd /usr/local/bin/republicd
                print_info "Binary installed successfully!"
            fi
        else
            curl -L "$BINARY_URL_ARCH" -o /tmp/republicd
            chmod +x /tmp/republicd
            sudo mv /tmp/republicd /usr/local/bin/republicd
            print_info "Binary installed successfully!"
        fi
        
        # Verify installation
        if republicd version &> /dev/null; then
            VERSION_OUTPUT=$(republicd version)
            print_info "Installed version: $VERSION_OUTPUT"
        fi
        echo ""
    fi
    
    # Initialize node
    print_info "Initializing node with moniker: $MONIKER"
    if [ -d "$REPUBLIC_HOME" ]; then
        print_warn "Directory $REPUBLIC_HOME already exists!"
        read -p "Do you want to remove it and reinitialize? [y/N]: " REINIT
        if [[ "$REINIT" =~ ^[Yy]$ ]]; then
            rm -rf "$REPUBLIC_HOME"
            if [[ "$IS_MAC" == false ]]; then
                republicd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$REPUBLIC_HOME"
                print_info "Node initialized successfully!"
            else
                print_warn "Cannot initialize on macOS without binary. Will use Docker."
                mkdir -p "$REPUBLIC_HOME/config"
            fi
        fi
    else
        if [[ "$IS_MAC" == false ]]; then
            republicd init "$MONIKER" --chain-id "$CHAIN_ID" --home "$REPUBLIC_HOME"
            print_info "Node initialized successfully!"
        else
            print_warn "Cannot initialize on macOS without binary. Will use Docker."
            mkdir -p "$REPUBLIC_HOME/config"
        fi
    fi
    echo ""
    
    # Download genesis
    print_info "Downloading genesis file..."
    curl -s "$GENESIS_URL" > "$REPUBLIC_HOME/config/genesis.json"
    print_info "Genesis file downloaded!"
    echo ""
    
    # Configure state sync (only if config.toml exists)
    if [ -f "$REPUBLIC_HOME/config/config.toml" ]; then
        if [ "$SYNC_MODE" = "1" ]; then
            print_info "Configuring state sync..."
            print_info "Fetching latest block height from $SNAP_RPC..."
            
            LATEST_HEIGHT=$(curl -s "$SNAP_RPC/block" | jq -r .result.block.header.height)
            if [ -n "$LATEST_HEIGHT" ] && [ "$LATEST_HEIGHT" != "null" ]; then
                BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
                TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
                if [ -n "$TRUST_HASH" ] && [ "$TRUST_HASH" != "null" ]; then
                    if [[ "$OS" == "Darwin" ]]; then
                        sed -i '' -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
                        s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
                        s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
                        s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"
                    else
                        sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
                        s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
                        s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
                        s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"
                    fi
                    print_info "State sync configured! Trust height: $BLOCK_HEIGHT"
                fi
            fi
        fi
        
        # Configure persistent peers
        print_info "Configuring persistent peers..."
        if [[ "$OS" == "Darwin" ]]; then
            sed -i '' -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"
        else
            sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"
        fi
        print_info "Persistent peers configured!"
    fi
    
    # Docker setup for Mac
    if [[ "$IS_MAC" == true ]]; then
        echo ""
        read -p "Do you want to setup and run Docker container? [Y/n]: " USE_DOCKER_INSTALL
        USE_DOCKER_INSTALL=${USE_DOCKER_INSTALL:-y}
        
        if [[ "$USE_DOCKER_INSTALL" =~ ^[Yy]$ ]]; then
            print_info "Setting up Docker container..."
            
            if ! check_command docker; then
                read -p "Press Enter to continue..."
                return 1
            fi
            
            if ! docker info &> /dev/null; then
                print_error "Docker is not running. Please start Docker Desktop first."
                read -p "Press Enter to continue..."
                return 1
            fi
            
            print_info "Docker is running!"
            print_info "Pulling Docker image: $DOCKER_IMAGE"
            docker pull "$DOCKER_IMAGE"
            
            if docker ps -a --format '{{.Names}}' | grep -q "^${DOCKER_CONTAINER}$"; then
                print_warn "Container '${DOCKER_CONTAINER}' already exists"
                read -p "Do you want to remove and recreate it? [y/N]: " OVERWRITE_CONTAINER
                if [[ "$OVERWRITE_CONTAINER" =~ ^[Yy]$ ]]; then
                    docker stop "$DOCKER_CONTAINER" 2>/dev/null || true
                    docker rm "$DOCKER_CONTAINER" 2>/dev/null || true
                    print_info "Removed existing container"
                else
                    print_info "Using existing container."
                    docker ps -a --filter name="$DOCKER_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                    read -p "Press Enter to continue..."
                    return 0
                fi
            fi
            
            # Initialize node in Docker if config.toml doesn't exist
            if [ ! -f "$REPUBLIC_HOME/config/config.toml" ]; then
                print_info "Initializing node in Docker container..."
                
                if [ -f "$REPUBLIC_HOME/config/genesis.json" ]; then
                    print_info "genesis.json already exists, using --overwrite flag..."
                    docker run --rm \
                        --user 0:0 \
                        -v "$REPUBLIC_HOME:/home/republic/.republicd" \
                        "$DOCKER_IMAGE" \
                        init "$MONIKER" --chain-id "$CHAIN_ID" --home /home/republic/.republicd --overwrite
                else
                    docker run --rm \
                        --user 0:0 \
                        -v "$REPUBLIC_HOME:/home/republic/.republicd" \
                        "$DOCKER_IMAGE" \
                        init "$MONIKER" --chain-id "$CHAIN_ID" --home /home/republic/.republicd
                fi
                
                curl -s "$GENESIS_URL" > "$REPUBLIC_HOME/config/genesis.json"
            fi
            
            # Configure state sync if needed
            if [ -f "$REPUBLIC_HOME/config/config.toml" ] && [ "$SYNC_MODE" = "1" ]; then
                print_info "Configuring state sync in config.toml..."
                LATEST_HEIGHT=$(curl -s "$SNAP_RPC/block" | jq -r .result.block.header.height)
                if [ -n "$LATEST_HEIGHT" ] && [ "$LATEST_HEIGHT" != "null" ]; then
                    BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
                    TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)
                    if [ -n "$TRUST_HASH" ] && [ "$TRUST_HASH" != "null" ]; then
                        if [[ "$OS" == "Darwin" ]]; then
                            sed -i '' -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
                            s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
                            s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
                            s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"
                        else
                            sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
                            s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
                            s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
                            s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"
                        fi
                        print_info "State sync configured! Trust height: $BLOCK_HEIGHT"
                    fi
                fi
                
                if [[ "$OS" == "Darwin" ]]; then
                    sed -i '' -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"
                else
                    sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"
                fi
                print_info "Persistent peers configured!"
            fi
            
            # Run Docker container
            print_info "Starting Docker container..."
            docker run -d --name "$DOCKER_CONTAINER" \
                --network host \
                -v "$REPUBLIC_HOME:/home/republic/.republicd" \
                "$DOCKER_IMAGE" \
                start --home /home/republic/.republicd --chain-id "$CHAIN_ID"
            
            if [ $? -eq 0 ]; then
                print_info "Docker container started successfully!"
                echo ""
                print_info "Container status:"
                docker ps --filter name="$DOCKER_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
            fi
        fi
    # Systemd service (Linux only)
    elif [[ "$IS_MAC" == false ]]; then
        echo ""
        read -p "Do you want to create a systemd service? [y/N]: " CREATE_SERVICE
        if [[ "$CREATE_SERVICE" =~ ^[Yy]$ ]]; then
            print_info "Creating systemd service..."
            
            SERVICE_USER=$(whoami)
            SERVICE_FILE="/etc/systemd/system/republicd.service"
            
            sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Republic Protocol Node
After=network-online.target

[Service]
User=$SERVICE_USER
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/republicd start --home $REPUBLIC_HOME --chain-id $CHAIN_ID
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
            
            sudo systemctl daemon-reload
            print_info "Systemd service created at $SERVICE_FILE"
            echo ""
            read -p "Do you want to enable and start the service now? [y/N]: " START_SERVICE
            if [[ "$START_SERVICE" =~ ^[Yy]$ ]]; then
                sudo systemctl enable republicd
                sudo systemctl start republicd
                print_info "Service enabled and started!"
            fi
        fi
    fi
    
    echo ""
    print_info "Installation completed!"
    print_info "Node directory: $REPUBLIC_HOME"
    print_info "Chain ID: $CHAIN_ID"
    print_info "Moniker: $MONIKER"
    print_info "Sync mode: $([ "$SYNC_MODE" = "1" ] && echo "State Sync" || echo "Full Sync from Genesis")"
    echo ""
    read -p "Press Enter to continue..."
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_node
fi
