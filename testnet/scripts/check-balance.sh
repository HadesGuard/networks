#!/bin/bash
# Check balance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_balance() {
    print_header "Check Balance"
    
    echo ""
    read -p "Enter address or key name: " ADDRESS_OR_KEY
    [ -z "$ADDRESS_OR_KEY" ] && { print_error "Address or key name cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    if [[ "$USE_DOCKER" == true ]]; then
        ADDRESS=$(docker exec "$DOCKER_CONTAINER" republicd keys show "$ADDRESS_OR_KEY" -a --home /home/republic/.republicd 2>/dev/null || echo "$ADDRESS_OR_KEY")
    else
        ADDRESS=$(republicd keys show "$ADDRESS_OR_KEY" -a --home "$REPUBLIC_HOME" 2>/dev/null || echo "$ADDRESS_OR_KEY")
    fi
    
    print_info "Querying balance for: $ADDRESS"
    echo ""
    
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec "$DOCKER_CONTAINER" republicd query bank balances "$ADDRESS" --home /home/republic/.republicd --output json | jq '.'
    else
        republicd query bank balances "$ADDRESS" --home "$REPUBLIC_HOME" --output json | jq '.'
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && check_balance
