#!/bin/bash
# Check validator and sync status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_validator_status() {
    print_header "Validator Status"
    
    echo ""
    read -p "Enter key name (or press Enter to list all validators): " KEY_NAME
    
    if [ -n "$KEY_NAME" ]; then
        print_info "Getting validator address..."
        if [[ "$USE_DOCKER" == true ]]; then
            VALIDATOR_ADDR=$(docker exec "$DOCKER_CONTAINER" republicd keys show "$KEY_NAME" --bech val -a --home /home/republic/.republicd 2>/dev/null)
        else
            VALIDATOR_ADDR=$(republicd keys show "$KEY_NAME" --bech val -a --home "$REPUBLIC_HOME" 2>/dev/null)
        fi
        
        [ -z "$VALIDATOR_ADDR" ] && { print_error "Failed to get validator address."; read -p "Press Enter..."; return 1; }
        
        print_info "Querying validator: $VALIDATOR_ADDR"
        echo ""
        
        if [[ "$USE_DOCKER" == true ]]; then
            docker exec "$DOCKER_CONTAINER" republicd query staking validator "$VALIDATOR_ADDR" --home /home/republic/.republicd --output json | jq '.'
        else
            republicd query staking validator "$VALIDATOR_ADDR" --home "$REPUBLIC_HOME" --output json | jq '.'
        fi
    else
        print_info "Listing all validators..."
        echo ""
        if [[ "$USE_DOCKER" == true ]]; then
            docker exec "$DOCKER_CONTAINER" republicd query staking validators --home /home/republic/.republicd --output json | jq '.validators[] | {moniker: .description.moniker, operator: .operator_address, status: .status, tokens: .tokens}'
        else
            republicd query staking validators --home "$REPUBLIC_HOME" --output json | jq '.validators[] | {moniker: .description.moniker, operator: .operator_address, status: .status, tokens: .tokens}'
        fi
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

check_sync_status() {
    print_header "Node Sync Status"
    
    echo ""
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec "$DOCKER_CONTAINER" republicd status --home /home/republic/.republicd 2>/dev/null | jq '.sync_info' || {
            print_error "Cannot get sync status. Is the node running?"
        }
    else
        republicd status --home "$REPUBLIC_HOME" 2>/dev/null | jq '.sync_info' || {
            print_error "Cannot get sync status. Is the node running?"
        }
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Run based on argument
case "${1:-validator}" in
    validator)
        check_validator_status
        ;;
    sync)
        check_sync_status
        ;;
    *)
        echo "Usage: $0 [validator|sync]"
        exit 1
        ;;
esac
