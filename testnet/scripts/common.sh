#!/bin/bash

# Common functions and configuration for Republic AI scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
VERSION="v0.1.0"
CHAIN_ID="raitestnet_77701-1"
REPUBLIC_HOME="${REPUBLIC_HOME:-$HOME/.republicd}"
BINARY_URL="https://media.githubusercontent.com/media/RepublicAI/networks/main/testnet/releases/${VERSION}/republicd-linux-amd64"
GENESIS_URL="https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json"
SNAP_RPC="https://statesync.republicai.io"
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
GAS_PRICES="250000000arai"
MIN_SELF_DELEGATION="1000000000000000000000"  # 1000 RAI
COMMISSION_RATE="0.10"
COMMISSION_MAX_RATE="0.20"
COMMISSION_MAX_CHANGE_RATE="0.01"
BACKUP_DIR="${BACKUP_DIR:-$HOME/republic-backups}"

# Detect OS and Docker
OS=$(uname -s)
IS_MAC=false
USE_DOCKER=false
DOCKER_CONTAINER="republicd"
DOCKER_IMAGE="ghcr.io/republicai/republicd:0.1.0"

if [[ "$OS" == "Darwin" ]]; then
    IS_MAC=true
    USE_DOCKER=true
fi

# Check if Docker is being used
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${DOCKER_CONTAINER}$"; then
    USE_DOCKER=true
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
}

# Execute command (Docker or direct)
exec_cmd() {
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec "$DOCKER_CONTAINER" "$@"
    else
        "$@"
    fi
}

# Execute command with home flag
exec_cmd_home() {
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec "$DOCKER_CONTAINER" "$1" --home /home/republic/.republicd "${@:2}"
    else
        "$1" --home "$REPUBLIC_HOME" "${@:2}"
    fi
}

# Check command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_error "$1 is not installed. Please install it first."
        return 1
    fi
    return 0
}

# Install prerequisites automatically
install_prerequisites() {
    print_info "Checking and installing prerequisites..."
    
    # Check and install curl
    if ! command -v curl &> /dev/null; then
        print_warn "curl is not installed. Installing..."
        if [[ "$OS" == "Darwin" ]]; then
            if command -v brew &> /dev/null; then
                brew install curl
            else
                print_error "Homebrew not found. Please install curl manually: brew install curl"
                return 1
            fi
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            sudo yum install -y curl
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y curl
        else
            print_error "Cannot auto-install curl. Please install it manually."
            return 1
        fi
        print_info "curl installed successfully!"
    else
        print_info "curl is already installed"
    fi
    
    # Check and install jq
    if ! command -v jq &> /dev/null; then
        print_warn "jq is not installed. Installing..."
        if [[ "$OS" == "Darwin" ]]; then
            if command -v brew &> /dev/null; then
                brew install jq
            else
                print_error "Homebrew not found. Please install jq manually: brew install jq"
                return 1
            fi
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq
        else
            print_error "Cannot auto-install jq. Please install it manually."
            return 1
        fi
        print_info "jq installed successfully!"
    else
        print_info "jq is already installed"
    fi
    
    return 0
}

# Detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
}

# Check if node is synced
check_sync() {
    print_info "Checking node sync status..."
    if [[ "$USE_DOCKER" == true ]]; then
        SYNC_INFO=$(docker exec "$DOCKER_CONTAINER" republicd status --home /home/republic/.republicd 2>/dev/null | jq -r '.sync_info.catching_up' 2>/dev/null || echo "unknown")
    else
        SYNC_INFO=$(republicd status --home "$REPUBLIC_HOME" 2>/dev/null | jq -r '.sync_info.catching_up' 2>/dev/null || echo "unknown")
    fi
    
    if [[ "$SYNC_INFO" == "false" ]]; then
        print_info "Node is fully synced!"
        return 0
    elif [[ "$SYNC_INFO" == "true" ]]; then
        print_warn "Node is still syncing. Please wait for sync to complete."
        return 1
    else
        print_error "Cannot check sync status. Is the node running?"
        return 1
    fi
}

# Source this file in other scripts
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # If script is run directly, just show config
    echo "Common functions and configuration loaded."
    echo "This script should be sourced, not executed directly."
    echo "Usage: source $0"
fi
