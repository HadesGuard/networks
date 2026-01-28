#!/bin/bash
# List keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

list_keys() {
    print_header "List Keys"
    
    echo ""
    if [[ "$USE_DOCKER" == true ]]; then
        docker exec "$DOCKER_CONTAINER" republicd keys list --home /home/republic/.republicd
    else
        republicd keys list --home "$REPUBLIC_HOME"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && list_keys
