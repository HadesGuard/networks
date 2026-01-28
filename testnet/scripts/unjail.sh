#!/bin/bash
# Unjail validator

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

unjail_validator() {
    print_header "Unjail Validator"
    
    echo ""
    read -p "Enter key name: " KEY_NAME
    [ -z "$KEY_NAME" ] && { print_error "Key name cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    print_info "Unjailing validator for key: $KEY_NAME"
    read -p "Confirm? [y/N]: " CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { print_info "Cancelled."; read -p "Press Enter..."; return 0; }
    
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec -it "$DOCKER_CONTAINER" republicd tx slashing unjail \
            --from="$KEY_NAME" --chain-id="$CHAIN_ID" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --home /home/republic/.republicd --yes
    else
        republicd tx slashing unjail \
            --from="$KEY_NAME" --chain-id="$CHAIN_ID" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --home "$REPUBLIC_HOME" --yes
    fi
    
    [ $? -eq 0 ] && print_info "Unjail transaction submitted!" || print_error "Failed to unjail."
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && unjail_validator
