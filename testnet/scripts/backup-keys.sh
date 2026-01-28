#!/bin/bash
# Backup keys

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

backup_keys() {
    print_header "Backup Keys"
    
    mkdir -p "$BACKUP_DIR"
    BACKUP_FILE="$BACKUP_DIR/republic-keys-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    print_info "Creating backup directory: $BACKUP_DIR"
    
    if [[ "$USE_DOCKER" == true ]]; then
        TEMP_DIR=$(mktemp -d)
        docker cp "${DOCKER_CONTAINER}:/home/republic/.republicd/keyring" "$TEMP_DIR/" 2>/dev/null || {
            print_error "Failed to copy keys from container."
            read -p "Press Enter..."
            return 1
        }
        tar -czf "$BACKUP_FILE" -C "$TEMP_DIR" keyring
        rm -rf "$TEMP_DIR"
    else
        [ ! -d "$REPUBLIC_HOME/keyring" ] && { print_error "Keyring directory not found."; read -p "Press Enter..."; return 1; }
        tar -czf "$BACKUP_FILE" -C "$REPUBLIC_HOME" keyring
    fi
    
    if [ -f "$BACKUP_FILE" ]; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        print_info "Backup created successfully!"
        print_info "Location: $BACKUP_FILE"
        print_info "Size: $BACKUP_SIZE"
        
        KEY_INFO_FILE="$BACKUP_DIR/key-info-$(date +%Y%m%d-%H%M%S).txt"
        if [[ "$USE_DOCKER" == true ]]; then
            docker exec "$DOCKER_CONTAINER" republicd keys list --home /home/republic/.republicd > "$KEY_INFO_FILE" 2>/dev/null || true
        else
            republicd keys list --home "$REPUBLIC_HOME" > "$KEY_INFO_FILE" 2>/dev/null || true
        fi
        print_info "Key info saved to: $KEY_INFO_FILE"
        print_warn "IMPORTANT: Keep your backup files secure and private!"
    else
        print_error "Failed to create backup!"
    fi
    
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && backup_keys
