# Republic AI Testnet

Welcome to the Republic AI testnet! This guide will help you join the network as a validator.

## Network Information

| Property | Value |
|----------|-------|
| Chain ID | `raitestnet_77701-1` |
| EVM Chain ID | `77701` |
| Bech32 Prefix | `rai` |
| Denom | `arai` (base), `RAI` (display) |
| Decimals | 18 |
| Min Gas Price | `250000000arai` |

## Public Endpoints

| Service | URL |
|---------|-----|
| Cosmos RPC | https://rpc.republicai.io |
| REST API | https://rest.republicai.io |
| Swagger | https://rest.republicai.io/swagger/ |
| gRPC | grpc.republicai.io:443 |
| EVM JSON-RPC | https://evm-rpc.republicai.io |

## Joining the Network

### Prerequisites

- Ubuntu 22.04 LTS (or similar Linux distribution)
- 4+ CPU cores
- 16GB+ RAM
- 500GB+ SSD
- curl, jq

### Quick Start with Script (Recommended)

Use our automated installation script:

```bash
cd testnet
./validator-manager.sh
```

Select option `1` to install and setup your node. The script will:
- Download and install the binary
- Initialize your node
- Configure state sync
- Set up persistent peers
- Optionally create systemd service

### Manual Installation

#### Option 1: State Sync (Recommended)

State sync allows you to quickly sync from a recent snapshot instead of syncing from genesis.

```bash
# 1. Install republicd binary
VERSION="v0.1.0"
curl -L "https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd

# 2. Initialize node
REPUBLIC_HOME="$HOME/.republicd"
republicd init <your-moniker> --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"

# 3. Download genesis
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"

# 4. Configure state sync
SNAP_RPC="https://statesync.republicai.io"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"

# 5. Configure persistent peers
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"

# 6. Start node
republicd start --home "$REPUBLIC_HOME" --chain-id raitestnet_77701-1
```

#### Option 2: Full Sync from Genesis

```bash
# 1. Install republicd binary
VERSION="v0.1.0"
curl -L "https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd

# 2. Initialize node
REPUBLIC_HOME="$HOME/.republicd"
republicd init <your-moniker> --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"

# 3. Download genesis
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"

# 4. Configure persistent peers
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"

# 5. Start node
republicd start --home "$REPUBLIC_HOME" --chain-id raitestnet_77701-1
```

### Alternative: Docker (Optional)

> **Note**: Docker is optional and mainly useful for macOS users or testing. For production, we recommend using the binary installation method above.

If you prefer Docker, you can use the installation script which will handle Docker setup automatically, or follow the manual Docker setup in the [scripts documentation](./scripts/README.md).

## Becoming a Validator

Once your node is fully synced, you can create a validator using the validator manager script:

```bash
cd testnet
./validator-manager.sh
```

Select option `2` to create a validator. The script will guide you through:
- Creating or importing a key
- Setting validator parameters (moniker, commission rates)
- Creating the validator transaction

### Manual Validator Creation

Alternatively, you can create a validator manually:

```bash
# 1. Create or import a key
republicd keys add <key-name>
# OR import existing key
republicd keys add <key-name> --recover

# 2. Get testnet tokens from faucet (contact team)

# 3. Create validator
republicd tx staking create-validator \
  --amount=1000000000000000000000arai \
  --pubkey=$(republicd comet show-validator) \
  --moniker="<your-moniker>" \
  --chain-id=raitestnet_77701-1 \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices="250000000arai" \
  --from=<key-name>
```

**Note**: Minimum self-delegation is 1000 RAI (1000000000000000000000 arai).

## Validator Management

Use the validator manager script for easy management:

```bash
cd testnet
./validator-manager.sh
```

Available functions:
- Create validator
- Stake/delegate tokens
- Backup and restore keys
- Check validator and sync status
- Unjail validator
- Check balance
- List and manage keys

### Manual Commands

If you prefer command line:

**Check Sync Status:**
```bash
republicd status --home $HOME/.republicd | jq '.sync_info'
```

**Check Validator Status:**
```bash
republicd query staking validator $(republicd keys show <key-name> --bech val -a --home $HOME/.republicd) --home $HOME/.republicd
```

**Unjail Validator:**
```bash
republicd tx slashing unjail --from <key-name> --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 250000000arai --home $HOME/.republicd
```

**Delegate Tokens:**
```bash
republicd tx staking delegate <validator-address> <amount>arai --from <key-name> --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 250000000arai --home $HOME/.republicd
```

## Systemd Service

Create `/etc/systemd/system/republicd.service`:

```ini
[Unit]
Description=Republic Protocol Node
After=network-online.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/local/bin/republicd start --home /home/ubuntu/.republicd --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

## Support

- GitHub Issues: https://github.com/RepublicAI/networks/issues
- Discord: https://discord.com/invite/therepublic
