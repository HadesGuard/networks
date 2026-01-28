#!/bin/bash
# Stake/Delegate tokens

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

stake_tokens() {
    print_header "Stake/Delegate Tokens"
    
    echo ""
    read -p "Enter key name: " KEY_NAME
    [ -z "$KEY_NAME" ] && { print_error "Key name cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    read -p "Enter validator address (or press Enter to self-delegate): " VALIDATOR_ADDR
    
    if [ -z "$VALIDATOR_ADDR" ]; then
        print_info "Getting validator address for self-delegation..."
        if [[ "$USE_DOCKER" == true ]]; then
            VALIDATOR_ADDR=$(docker exec "$DOCKER_CONTAINER" republicd keys show "$KEY_NAME" --bech val -a --home /home/republic/.republicd 2>/dev/null)
        else
            VALIDATOR_ADDR=$(republicd keys show "$KEY_NAME" --bech val -a --home "$REPUBLIC_HOME" 2>/dev/null)
        fi
        [ -z "$VALIDATOR_ADDR" ] && { print_error "Failed to get validator address."; read -p "Press Enter..."; return 1; }
        print_info "Self-delegating to: $VALIDATOR_ADDR"
    fi
    
    read -p "Enter amount to stake (in RAI): " AMOUNT_RAI
    [ -z "$AMOUNT_RAI" ] && { print_error "Amount cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    AMOUNT_ARAI="${AMOUNT_RAI}000000000000000000"
    print_info "Staking $AMOUNT_RAI RAI to $VALIDATOR_ADDR"
    read -p "Confirm? [y/N]: " CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { print_info "Cancelled."; read -p "Press Enter..."; return 0; }
    
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec -it "$DOCKER_CONTAINER" republicd tx staking delegate \
            "$VALIDATOR_ADDR" "${AMOUNT_ARAI}arai" \
            --from="$KEY_NAME" --chain-id="$CHAIN_ID" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --home /home/republic/.republicd --yes
    else
        republicd tx staking delegate \
            "$VALIDATOR_ADDR" "${AMOUNT_ARAI}arai" \
            --from="$KEY_NAME" --chain-id="$CHAIN_ID" \
            --gas=auto --gas-adjustment=1.5 --gas-prices="$GAS_PRICES" \
            --home "$REPUBLIC_HOME" --yes
    fi
    
    [ $? -eq 0 ] && print_info "Delegation transaction submitted!" || print_error "Failed to delegate."
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && stake_tokens
