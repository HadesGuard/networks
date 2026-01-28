#!/bin/bash
# Restore keys from backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

restore_keys() {
    print_header "Restore Keys from Backup"
    
    echo ""
    print_info "Available backups in $BACKUP_DIR:"
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | nl || {
        print_error "No backup files found in $BACKUP_DIR"
        read -p "Press Enter..."
        return 1
    }
    
    echo ""
    read -p "Enter backup file number (or full path): " BACKUP_SELECTION
    
    if [[ "$BACKUP_SELECTION" =~ ^[0-9]+$ ]]; then
        BACKUP_FILE=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | sed -n "${BACKUP_SELECTION}p")
    else
        BACKUP_FILE="$BACKUP_SELECTION"
    fi
    
    [ ! -f "$BACKUP_FILE" ] && { print_error "Backup file not found: $BACKUP_FILE"; read -p "Press Enter..."; return 1; }
    
    print_warn "This will restore keys from: $BACKUP_FILE"
    print_warn "Existing keys may be overwritten!"
    read -p "Confirm restore? [y/N]: " CONFIRM
    [[ ! "$CONFIRM" =~ ^[Yy]$ ]] && { print_info "Cancelled."; read -p "Press Enter..."; return 0; }
    
    if [[ "$USE_DOCKER" == true ]]; then
        docker stop "$DOCKER_CONTAINER" 2>/dev/null || true
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
        [ -d "$REPUBLIC_HOME/keyring" ] && mv "$REPUBLIC_HOME/keyring" "$REPUBLIC_HOME/keyring.backup.$(date +%s)"
        cp -r "$TEMP_DIR/keyring" "$REPUBLIC_HOME/"
        rm -rf "$TEMP_DIR"
        docker start "$DOCKER_CONTAINER" 2>/dev/null || true
    else
        [ -d "$REPUBLIC_HOME/keyring" ] && mv "$REPUBLIC_HOME/keyring" "$REPUBLIC_HOME/keyring.backup.$(date +%s)"
        tar -xzf "$BACKUP_FILE" -C "$REPUBLIC_HOME"
    fi
    
    print_info "Restore completed!"
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && restore_keys
