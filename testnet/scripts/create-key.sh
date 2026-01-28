#!/bin/bash
# Create/Import key

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

create_import_key() {
    print_header "Create/Import Key"
    
    echo ""
    echo "1) Create new key"
    echo "2) Import existing key from mnemonic"
    read -p "Choose option [1-2]: " OPTION
    
    read -p "Enter key name: " KEY_NAME
    [ -z "$KEY_NAME" ] && { print_error "Key name cannot be empty!"; read -p "Press Enter..."; return 1; }
    
    if [[ "$OPTION" == "1" ]]; then
        print_info "Creating new key: $KEY_NAME"
        if [[ "$USE_DOCKER" == true ]]; then
            docker exec -it "$DOCKER_CONTAINER" republicd keys add "$KEY_NAME" --home /home/republic/.republicd
        else
            republicd keys add "$KEY_NAME" --home "$REPUBLIC_HOME"
        fi
    elif [[ "$OPTION" == "2" ]]; then
        print_info "Importing key from mnemonic: $KEY_NAME"
        if [[ "$USE_DOCKER" == true ]]; then
            docker exec -it "$DOCKER_CONTAINER" republicd keys add "$KEY_NAME" --recover --home /home/republic/.republicd
        else
            republicd keys add "$KEY_NAME" --recover --home "$REPUBLIC_HOME"
        fi
    else
        print_error "Invalid option!"
        read -p "Press Enter..."
        return 1
    fi
    
    [ $? -eq 0 ] && print_info "Key operation completed!" || print_error "Failed to create/import key."
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && create_import_key
