#!/bin/bash
# Create validator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

create_validator() {
    print_header "Create Validator"
    
    if ! check_sync; then
        print_error "Node must be fully synced before creating validator."
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo ""
    read -p "Enter key name: " KEY_NAME
    [ -z "$KEY_NAME" ] && { print_error "Key name cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    if ! exec_cmd republicd keys show "$KEY_NAME" &>/dev/null; then
        print_error "Key '$KEY_NAME' not found!"
        read -p "Do you want to create a new key? [y/N]: " CREATE_KEY
        [[ "$CREATE_KEY" =~ ^[Yy]$ ]] && exec_cmd republicd keys add "$KEY_NAME" || { read -p "Press Enter..."; return 1; }
    fi
    
    read -p "Enter moniker (validator name): " MONIKER
    [ -z "$MONIKER" ] && { print_error "Moniker cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    read -p "Enter amount to stake (in RAI, minimum 1000): " AMOUNT_RAI
    AMOUNT_RAI=${AMOUNT_RAI:-1000}
    AMOUNT_ARAI="${AMOUNT_RAI}000000000000000000"
    
    read -p "Commission rate (default 0.10 = 10%): " COMM_RATE
    COMM_RATE=${COMM_RATE:-$COMMISSION_RATE}
    read -p "Max commission rate (default 0.20 = 20%): " COMM_MAX
    COMM_MAX=${COMM_MAX:-$COMMISSION_MAX_RATE}
    read -p "Max commission change rate (default 0.01 = 1%): " COMM_CHANGE
    COMM_CHANGE=${COMM_CHANGE:-$COMMISSION_MAX_CHANGE_RATE}
    
    print_info "Getting validator public key..."
    if [[ "$USE_DOCKER" == true ]]; then
        VALIDATOR_PUBKEY=$(docker exec "$DOCKER_CONTAINER" republicd comet show-validator --home /home/republic/.republicd 2>/dev/null)
    else
        VALIDATOR_PUBKEY=$(republicd comet show-validator --home "$REPUBLIC_HOME" 2>/dev/null)
    fi
    
    [ -z "$VALIDATOR_PUBKEY" ] && { print_error "Failed to get validator public key."; read -p "Press Enter..."; return 1; }
    
    echo ""
    print_warn "Transaction details:"
    echo "  Moniker: $MONIKER"
    echo "  Amount: $AMOUNT_RAI RAI"
    echo "  Commission Rate: $COMM_RATE"
    echo ""
    read -p "Confirm create validator? [y/N]: " CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { print_info "Cancelled."; read -p "Press Enter..."; return 0; }
    
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec -it "$DOCKER_CONTAINER" republicd tx staking create-validator \
            --amount="${AMOUNT_ARAI}arai" \
            --pubkey="$VALIDATOR_PUBKEY" \
            --moniker="$MONIKER" \
            --chain-id="$CHAIN_ID" \
            --commission-rate="$COMM_RATE" \
            --commission-max-rate="$COMM_MAX" \
            --commission-max-change-rate="$COMM_CHANGE" \
            --min-self-delegation="1" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --from="$KEY_NAME" --home /home/republic/.republicd --yes
    else
        republicd tx staking create-validator \
            --amount="${AMOUNT_ARAI}arai" \
            --pubkey="$VALIDATOR_PUBKEY" \
            --moniker="$MONIKER" \
            --chain-id="$CHAIN_ID" \
            --commission-rate="$COMM_RATE" \
            --commission-max-rate="$COMM_MAX" \
            --commission-max-change-rate="$COMM_CHANGE" \
            --min-self-delegation="1" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --from="$KEY_NAME" --home "$REPUBLIC_HOME" --yes
    fi
    
    [ $? -eq 0 ] && print_info "Validator creation transaction submitted!" || print_error "Failed to create validator."
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && create_validator
