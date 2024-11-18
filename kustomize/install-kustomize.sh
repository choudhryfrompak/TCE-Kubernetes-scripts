#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print error messages
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

# Function to print success messages
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

# Function to print info messages
info() {
    echo -e "${YELLOW}INFO: $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check and create directory if it doesn't exist
check_and_create_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        info "Creating directory: $dir"
        mkdir -p "$dir" || {
            error "Failed to create directory: $dir"
            exit 1
        }
    fi
}

# Function to install dependencies
install_dependencies() {
    info "Checking and installing dependencies..."
    
    local deps=("curl" "git")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        info "Installing missing dependencies: ${missing_deps[*]}"
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y "${missing_deps[@]}"
        elif command_exists yum; then
            sudo yum install -y "${missing_deps[@]}"
        else
            error "Package manager not found. Please install dependencies manually: ${missing_deps[*]}"
            exit 1
        fi
    fi
}

# Function to download and install kustomize
install_kustomize() {
    local install_dir="/usr/local/bin"
    local temp_dir="/tmp/kustomize_install"

    # Check if kustomize is already installed
    if command_exists kustomize; then
        local current_version=$(kustomize version --short)
        info "Kustomize is already installed: $current_version"
        read -p "Do you want to reinstall? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            success "Keeping existing kustomize installation"
            exit 0
        fi
    fi

    # Create temporary directory
    check_and_create_dir "$temp_dir"
    cd "$temp_dir" || {
        error "Failed to change to temporary directory"
        exit 1
    }

    # Download and execute the installation script
    info "Downloading kustomize installation script..."
    if ! curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" -o install_kustomize.sh; then
        error "Failed to download installation script"
        exit 1
    fi

    # Make script executable
    chmod +x install_kustomize.sh

    # Run installation script
    info "Installing kustomize..."
    if ! ./install_kustomize.sh; then
        error "Failed to install kustomize"
        exit 1
    fi

    # Move kustomize to installation directory
    info "Moving kustomize to $install_dir"
    if ! sudo mv kustomize "$install_dir/"; then
        error "Failed to move kustomize to $install_dir"
        exit 1
    fi

    # Verify installation
    if command_exists kustomize; then
        local installed_version=$(kustomize version --short)
        success "Kustomize installed successfully: $installed_version"
    else
        error "Kustomize installation verification failed"
        exit 1
    fi

    # Cleanup
    info "Cleaning up temporary files..."
    cd - > /dev/null
    rm -rf "$temp_dir"
}

# Main execution
main() {
    # Check if script is run as root
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root"
        exit 1
    fi

    # Install dependencies
    install_dependencies

    # Install kustomize
    install_kustomize
}

# Run main function
main
