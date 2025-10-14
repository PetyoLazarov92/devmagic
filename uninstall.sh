#!/bin/bash

# Dev Magic Uninstallation Script
# Removes Dev Magic from the system

set -e

# Configuration
INSTALL_DIR="/usr/local/share/devmagic"
BIN_DIR="/usr/local/bin"
SCRIPT_NAME="devmagic"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Dev Magic is installed
check_installation() {
    if [[ ! -d "$INSTALL_DIR" ]] && [[ ! -f "$BIN_DIR/$SCRIPT_NAME" ]]; then
        log_error "Dev Magic does not appear to be installed"
        exit 1
    fi
}

# Remove installation files
remove_files() {
    log_info "Removing Dev Magic installation..."
    
    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        sudo rm -rf "$INSTALL_DIR"
        log_success "Removed $INSTALL_DIR"
    fi
    
    # Remove command wrapper
    if [[ -f "$BIN_DIR/$SCRIPT_NAME" ]]; then
        sudo rm "$BIN_DIR/$SCRIPT_NAME"
        log_success "Removed $BIN_DIR/$SCRIPT_NAME"
    fi
}

# Optional cleanup
optional_cleanup() {
    echo
    log_info "Optional cleanup options:"
    echo
    
    # Ask about removing certificates
    read -p "Do you want to remove SSL certificates created by Dev Magic? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local certs_dir="/etc/ssl/localcerts"
        
        if [[ -d "$certs_dir" ]]; then
            rm -rf "$certs_dir"
            log_success "Removed certificates directory: $certs_dir"
        fi
    fi
    
    # Ask about removing Apache configurations
    read -p "Do you want to remove Apache virtual host configurations created by Dev Magic? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Please manually remove Apache configurations from:"
        echo "  /etc/apache2/sites-available/"
        echo "  /etc/apache2/sites-enabled/"
        echo "Look for files containing 'local.' domains"
    fi
    
    # Ask about removing WordPress installations
    read -p "Do you want to remove WordPress installations in /var/www/? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Please manually remove WordPress installations from:"
        echo "  /var/www/"
        echo "Look for directories with 'local.' domain names"
    fi
}

# Main uninstallation function
main() {
    echo "======================================"
    echo "  Dev Magic Uninstallation Script"
    echo "======================================"
    echo
    
    check_installation
    
    echo "This will remove Dev Magic from your system."
    read -p "Are you sure you want to continue? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi
    
    remove_files
    optional_cleanup
    
    echo
    log_success "Dev Magic uninstalled successfully!"
    echo
    echo "Thank you for using Dev Magic!"
}

# Run main function
main "$@"
