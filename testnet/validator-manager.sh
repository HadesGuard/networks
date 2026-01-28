#!/bin/bash

# Republic AI Validator Manager - Main Menu
# This script provides a menu interface to call individual scripts

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Source common functions for menu display
source "$SCRIPTS_DIR/common.sh"

# Functions
print_menu() {
    clear
    print_header "Republic AI Validator Manager"
    echo ""
    echo -e "${GREEN}1)${NC} Install/Setup Node"
    echo -e "${GREEN}2)${NC} Create Validator"
    echo -e "${GREEN}3)${NC} Stake/Delegate Tokens"
    echo -e "${GREEN}4)${NC} Backup Keys"
    echo -e "${GREEN}5)${NC} Restore Keys from Backup"
    echo -e "${GREEN}6)${NC} Check Validator Status"
    echo -e "${GREEN}7)${NC} Check Node Sync Status"
    echo -e "${GREEN}8)${NC} Unjail Validator"
    echo -e "${GREEN}9)${NC} Check Balance"
    echo -e "${GREEN}10)${NC} List Keys"
    echo -e "${GREEN}11)${NC} Create/Import Key"
    echo -e "${GREEN}0)${NC} Exit"
    echo ""
}

# Main menu loop
main() {
    while true; do
        print_menu
        read -p "Select option: " CHOICE
        
        case $CHOICE in
            1)
                "$SCRIPTS_DIR/install-node.sh"
                ;;
            2)
                "$SCRIPTS_DIR/create-validator.sh"
                ;;
            3)
                "$SCRIPTS_DIR/stake.sh"
                ;;
            4)
                "$SCRIPTS_DIR/backup-keys.sh"
                ;;
            5)
                "$SCRIPTS_DIR/restore-keys.sh"
                ;;
            6)
                "$SCRIPTS_DIR/check-status.sh" validator
                ;;
            7)
                "$SCRIPTS_DIR/check-status.sh" sync
                ;;
            8)
                "$SCRIPTS_DIR/unjail.sh"
                ;;
            9)
                "$SCRIPTS_DIR/check-balance.sh"
                ;;
            10)
                "$SCRIPTS_DIR/list-keys.sh"
                ;;
            11)
                "$SCRIPTS_DIR/create-key.sh"
                ;;
            0)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option!"
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"
