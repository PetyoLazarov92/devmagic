#!/bin/bash

# Dev Magic Installation Script
# Installs Dev Magic system-wide for all users

set -e

# Configuration
INSTALL_DIR="/usr/local/share/devmagic"
BIN_DIR="/usr/local/bin"
SCRIPT_NAME="devmagic"
REQUIRED_DEPS=("apache2" "mysql-server" "php" "curl" "git" "openssl")
RECOMMENDED_DEPS=("wp-cli" "composer")

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Don't run this script as root. Use sudo when prompted."
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    log_info "Checking system dependencies..."
    
    local missing_deps=()
    local missing_recommended=()
    
    # Check required dependencies
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! command -v "$dep" &> /dev/null && ! dpkg -l | grep -q "^ii.*$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    # Check recommended dependencies
    for dep in "${RECOMMENDED_DEPS[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_recommended+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_warning "Missing required dependencies: ${missing_deps[*]}"
        echo "Install with: sudo apt update && sudo apt install ${missing_deps[*]}"
        read -p "Do you want to install missing dependencies now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo apt update
            sudo apt install "${missing_deps[@]}"
        else
            log_error "Required dependencies must be installed before continuing."
            exit 1
        fi
    fi
    
    if [[ ${#missing_recommended[@]} -gt 0 ]]; then
        log_warning "Missing recommended dependencies: ${missing_recommended[*]}"
        echo "These are optional but recommended for full functionality."
    fi
}

# Create installation directories
create_directories() {
    log_info "Creating installation directories..."
    sudo mkdir -p "$INSTALL_DIR"
    sudo mkdir -p "$BIN_DIR"
    log_success "Directories created successfully"
}

# Install files
install_files() {
    log_info "Installing Dev Magic files to $INSTALL_DIR..."
    
    # Copy all files to installation directory
    sudo cp -r ./* "$INSTALL_DIR/"
    
    # Make main script executable
    sudo chmod +x "$INSTALL_DIR/mklocalenv.sh"
    
    # Remove the install script from the installation directory
    sudo rm -f "$INSTALL_DIR/install.sh" "$INSTALL_DIR/uninstall.sh"
    
    log_success "Files installed successfully"
}

# Create wrapper script
create_wrapper() {
    log_info "Creating command wrapper..."
    
    sudo tee "$BIN_DIR/$SCRIPT_NAME" > /dev/null <<EOF
#!/bin/bash
# Dev Magic command wrapper
# This script allows running Dev Magic from anywhere in the system

exec "$INSTALL_DIR/mklocalenv.sh" "\$@"
EOF
    
    # Make wrapper executable
    sudo chmod +x "$BIN_DIR/$SCRIPT_NAME"
    
    log_success "Command wrapper created at $BIN_DIR/$SCRIPT_NAME"
}

# Setup post-installation configuration
post_install_setup() {
    log_info "Performing post-installation setup..."
    
    # Enable Apache modules
    if command -v a2enmod >/dev/null 2>&1; then
        sudo a2enmod ssl >/dev/null 2>&1 || true
        sudo a2enmod rewrite >/dev/null 2>&1 || true
        log_success "Apache SSL and rewrite modules enabled"
    fi
    
    # Create certs directory for current user
    local current_user=$(logname 2>/dev/null || echo "$USER")
    local certs_dir="/etc/ssl/localcerts/cert-issuer"
    
    if [[ ! -d "$certs_dir" ]]; then
        sudo mkdir -p "$certs_dir"
        log_success "Created certificates directory: $certs_dir"
    fi
    
    # Check PATH
    if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
        log_warning "/usr/local/bin is not in your PATH"
        echo "Add this line to your ~/.bashrc or ~/.zshrc:"
        echo "export PATH=\"/usr/local/bin:\$PATH\""
        echo "Then run: source ~/.bashrc"
    fi
}

# Main installation function
main() {
    echo "======================================"
    echo "   Dev Magic Installation Script"
    echo "======================================"
    echo

    check_root
    check_dependencies
    create_directories
    install_files
    create_wrapper
    post_install_setup

    echo
    log_success "Dev Magic installed successfully!"
    echo
    echo "Usage examples:"
    echo "  devmagic --help"
    echo "  devmagic --config-wizard"
    echo "  devmagic --wizard"
    echo "  devmagic -d local.example.com -c -w -cf"
    echo
    echo "For more information, run: devmagic --help"
}

# Run main function
main "$@"