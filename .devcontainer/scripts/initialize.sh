#!/bin/bash

# ========================================================================
# Devcontainer Initialize Script
# ========================================================================
# This script runs on the host before container creation and:
# - Validates 1Password CLI is installed and user is signed in
# - Generates .env file from .env.template using 1Password secrets
#
# This script is executed via the initializeCommand in devcontainer.json
# ========================================================================

set -e  # Exit on error

# Add Nix and common package manager paths
# Nix-darwin packages are typically in /run/current-system/sw/bin
# User Nix packages in ~/.nix-profile/bin
# System Nix packages in /nix/var/nix/profiles/default/bin
export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/opt/homebrew/bin:/usr/local/bin:/opt/local/bin:$PATH"

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for output
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

# ------------------------------------------------------------------------
# Step 1: Setup Paths
# ------------------------------------------------------------------------
# Get the directory where this script is located (.devcontainer/scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVCONTAINER_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Initializing devcontainer environment..."

# ------------------------------------------------------------------------
# Step 2: Ensure op CLI symlink exists
# ------------------------------------------------------------------------
# 1Password app integration requires op to be in /usr/local/bin for older versions
OP_SOURCE=$(command -v op 2>/dev/null || echo "")
if [ -n "$OP_SOURCE" ] && [ "$OP_SOURCE" != "/usr/local/bin/op" ]; then
    if [ ! -e "/usr/local/bin/op" ]; then
        log_info "Creating symlink for 1Password CLI app integration..."
        sudo mkdir -p /usr/local/bin
        sudo ln -sf "$OP_SOURCE" /usr/local/bin/op
        log_success "Symlink created: /usr/local/bin/op -> $OP_SOURCE"
    fi
fi

# ------------------------------------------------------------------------
# Step 2: Validate 1Password CLI
# ------------------------------------------------------------------------
log_info "Validating 1Password CLI..."

if ! command -v op >/dev/null 2>&1; then
    log_error "1Password CLI (op) is not installed."
    echo ""
    echo "Please install it from:"
    echo "  https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

log_success "1Password CLI found."

# ------------------------------------------------------------------------
# Step 3: Verify 1Password Authentication
# ------------------------------------------------------------------------
log_info "Checking 1Password authentication..."

if ! op whoami >/dev/null 2>&1; then
    log_warning "You are not signed in to 1Password."
    log_info "Attempting to sign in..."
    echo ""
    
    # Attempt to sign in (this will prompt the user interactively)
    if ! op signin; then
        echo ""
        log_error "Failed to sign in to 1Password."
        echo ""
        echo "Please sign in manually with: op signin"
        exit 1
    fi
    
    echo ""
    log_success "Successfully signed in to 1Password!"
else
    log_success "Already signed in to 1Password."
fi

# ------------------------------------------------------------------------
# Step 4: Generate .env File
# ------------------------------------------------------------------------
log_info "Generating .env file from 1Password secrets..."

ENV_TEMPLATE="$DEVCONTAINER_DIR/.env.template"
ENV_FILE="$DEVCONTAINER_DIR/.env"

if [ ! -f "$ENV_TEMPLATE" ]; then
    log_error "Template file not found: $ENV_TEMPLATE"
    exit 1
fi

# Generate .env file using 1Password CLI
if op inject -f -i "$ENV_TEMPLATE" -o "$ENV_FILE" --file-mode 0644; then
    log_success "Devcontainer .env file created successfully!"
else
    log_error "Failed to generate .env file."
    exit 1
fi

# ------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------
echo ""
log_success "=========================================="
log_success "Devcontainer Initialization Complete!"
log_success "=========================================="
echo ""
log_info "Container build will now proceed..."
