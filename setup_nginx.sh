#!/bin/bash

# Nginx Setup Script for Cookie-Based Session Management
# This script detects Homebrew installation location (standard or custom),
# installs nginx if needed, and configures it with the example config file.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_EXAMPLE="${SCRIPT_DIR}/nginx.conf.example"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect Homebrew installation location
detect_brew_location() {
    print_info "Detecting Homebrew installation location..."
    
    # Check if brew command exists
    if ! command -v brew &> /dev/null; then
        print_error "Homebrew is not installed or not in PATH"
        exit 1
    fi
    
    # Get brew prefix
    BREW_PREFIX=$(brew --prefix)
    
    if [ -z "$BREW_PREFIX" ]; then
        print_error "Could not determine Homebrew prefix"
        exit 1
    fi
    
    print_success "Found Homebrew at: ${BREW_PREFIX}"
    
    # Determine if it's standard or custom location
    if [ "$BREW_PREFIX" = "/opt/homebrew" ]; then
        print_info "Detected standard Homebrew installation (Apple Silicon)"
        BREW_TYPE="standard_arm"
    elif [ "$BREW_PREFIX" = "/usr/local" ]; then
        print_info "Detected standard Homebrew installation (Intel)"
        BREW_TYPE="standard_intel"
    else
        print_warning "Detected custom Homebrew installation at: ${BREW_PREFIX}"
        BREW_TYPE="custom"
    fi
    
    NGINX_ETC_DIR="${BREW_PREFIX}/etc/nginx"
    NGINX_SERVERS_DIR="${NGINX_ETC_DIR}/servers"
    
    print_info "Nginx config directory: ${NGINX_ETC_DIR}"
    print_info "Nginx servers directory: ${NGINX_SERVERS_DIR}"
}

# Function to check if nginx is installed
check_nginx_installed() {
    print_info "Checking if nginx is installed..."
    
    if command -v nginx &> /dev/null; then
        NGINX_VERSION=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')
        print_success "Nginx is installed (version: ${NGINX_VERSION})"
        
        # Check if nginx is installed via Homebrew
        NGINX_PATH=$(which nginx)
        if [[ "$NGINX_PATH" == *"$BREW_PREFIX"* ]]; then
            print_info "Nginx is installed via Homebrew"
            return 0
        else
            print_warning "Nginx is installed but not via Homebrew (found at: ${NGINX_PATH})"
            print_warning "This script will install nginx via Homebrew, which may conflict"
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Aborted by user"
                exit 1
            fi
        fi
    else
        print_warning "Nginx is not installed"
        return 1
    fi
}

# Function to install nginx via Homebrew
install_nginx() {
    print_info "Installing nginx via Homebrew..."
    
    if brew install nginx; then
        print_success "Nginx installed successfully"
    else
        print_error "Failed to install nginx"
        exit 1
    fi
}

# Function to check if auth_request module is available
check_auth_request_module() {
    print_info "Checking for auth_request module..."
    
    if nginx -V 2>&1 | grep -q "with-http_auth_request_module"; then
        print_success "auth_request module is available"
        return 0
    else
        print_error "auth_request module is not available"
        print_error "You may need to compile nginx with this module"
        exit 1
    fi
}

# Function to create necessary directories
create_directories() {
    print_info "Creating necessary directories..."
    
    # Create servers directory if it doesn't exist
    if [ ! -d "$NGINX_SERVERS_DIR" ]; then
        print_info "Creating servers directory: ${NGINX_SERVERS_DIR}"
        mkdir -p "$NGINX_SERVERS_DIR"
        print_success "Created servers directory"
    else
        print_info "Servers directory already exists"
    fi
    
    # Check if main nginx.conf includes servers directory
    NGINX_CONF="${NGINX_ETC_DIR}/nginx.conf"
    if [ -f "$NGINX_CONF" ]; then
        if grep -q "include servers" "$NGINX_CONF"; then
            print_success "Main nginx.conf includes servers directory"
        else
            print_warning "Main nginx.conf does not include servers directory"
            print_warning "You may need to add 'include servers/*;' to your nginx.conf"
            print_info "Checking if we should add it automatically..."
            
            # Check if there's an http block
            if grep -q "http {" "$NGINX_CONF"; then
                read -p "Add 'include servers/*;' to nginx.conf? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Find a good place to add it (after other includes in http block)
                    if grep -q "include.*mime.types" "$NGINX_CONF"; then
                        # Add after mime.types include
                        sed -i.bak '/include.*mime.types/a\
    include servers/*;
' "$NGINX_CONF"
                        print_success "Added 'include servers/*;' to nginx.conf"
                    else
                        print_warning "Could not automatically add include statement"
                        print_info "Please manually add 'include servers/*;' to your nginx.conf in the http block"
                    fi
                fi
            fi
        fi
    else
        print_error "Main nginx.conf not found at: ${NGINX_CONF}"
        exit 1
    fi
}

# Function to copy and configure nginx config
configure_nginx() {
    print_info "Configuring nginx with example config..."
    
    if [ ! -f "$CONFIG_EXAMPLE" ]; then
        print_error "Example config file not found: ${CONFIG_EXAMPLE}"
        exit 1
    fi
    
    NGINX_CONFIG="${NGINX_SERVERS_DIR}/node-cookies.conf"
    
    # Check if config already exists
    if [ -f "$NGINX_CONFIG" ]; then
        print_warning "Config file already exists: ${NGINX_CONFIG}"
        read -p "Overwrite existing config? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing config"
            return 0
        fi
        # Backup existing config
        BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$NGINX_CONFIG" "$BACKUP_FILE"
        print_info "Backed up existing config to: ${BACKUP_FILE}"
    fi
    
    # Copy config file
    cp "$CONFIG_EXAMPLE" "$NGINX_CONFIG"
    print_success "Copied config to: ${NGINX_CONFIG}"
    
    # Prompt for configuration customization
    print_info "You should customize the following settings in the config file:"
    echo "  1. server_name (line 13) - Change 'example.com' to your domain or 'localhost'"
    echo "  2. root directory (line 16) - Change '/var/www/html' to your web root"
    echo "  3. upstream server (line 7) - Verify Node.js app host/port"
    echo "  4. protected directory path (line 46) - Update to your protected folder"
    echo ""
    read -p "Open config file for editing now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Try to open with default editor
        if [ -n "$EDITOR" ]; then
            $EDITOR "$NGINX_CONFIG"
        elif command -v nano &> /dev/null; then
            nano "$NGINX_CONFIG"
        elif command -v vim &> /dev/null; then
            vim "$NGINX_CONFIG"
        else
            print_warning "No editor found. Please edit manually: ${NGINX_CONFIG}"
        fi
    fi
}

# Function to test nginx configuration
test_nginx_config() {
    print_info "Testing nginx configuration..."
    
    if sudo nginx -t 2>&1; then
        print_success "Nginx configuration test passed"
        return 0
    else
        print_error "Nginx configuration test failed"
        print_error "Please fix the errors above before proceeding"
        return 1
    fi
}

# Function to provide next steps
print_next_steps() {
    echo ""
    print_success "Setup complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Customize the config file: ${NGINX_SERVERS_DIR}/node-cookies.conf"
    echo "  2. Create the protected directory and set permissions"
    echo "  3. Ensure your Node.js app is running on the configured port"
    echo "  4. Test the configuration: sudo nginx -t"
    echo "  5. Reload nginx: sudo nginx -s reload"
    echo ""
    print_info "For detailed instructions, see README_nginx_setup.md"
    echo ""
}

# Main execution
main() {
    echo ""
    print_info "=========================================="
    print_info "Nginx Setup Script"
    print_info "=========================================="
    echo ""
    
    # Detect Homebrew location
    detect_brew_location
    echo ""
    
    # Check if nginx is installed
    if ! check_nginx_installed; then
        echo ""
        read -p "Install nginx via Homebrew? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            install_nginx
        else
            print_error "Nginx installation required to continue"
            exit 1
        fi
    fi
    echo ""
    
    # Check auth_request module
    check_auth_request_module
    echo ""
    
    # Create directories
    create_directories
    echo ""
    
    # Configure nginx
    configure_nginx
    echo ""
    
    # Test configuration
    if test_nginx_config; then
        echo ""
        print_next_steps
    else
        echo ""
        print_error "Please fix configuration errors and run this script again"
        exit 1
    fi
}

# Run main function
main

