#!/bin/bash

# ========================================================================
# macOS ARM Generate Environment Script
# ========================================================================
# This script generates the .env file from 1Password secrets.
# Run this whenever you need to update environment variables from 1Password.
#
# Usage: ./generate-env.sh <hostname>
# Example: ./generate-env.sh keith-macbook-pro
# ========================================================================

set -e  # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load shared script helpers
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "Generate Environment" "Creates .env file from 1Password secrets"

# ------------------------------------------------------------------------
# Step 0: Parse Arguments and Setup Paths
# ------------------------------------------------------------------------
HOSTNAME="${1:-}"

if [ -z "$HOSTNAME" ]; then
    log_error "No hostname provided."
    echo ""
    echo "Usage: $0 <hostname>"
    echo ""
    echo "Example: $0 keith-macbook-pro"
    echo ""
    
    # Determine the git repo root directory
    REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "")
    
    if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/hosts" ]; then
        echo "Available hosts:"
        ls -1 "$REPO_ROOT/hosts" | sed 's/^/  - /'
    fi
    
    exit 1
fi

log_info "Generating .env file for host: $HOSTNAME"

# Determine the git repo root directory
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "")

if [ -z "$REPO_ROOT" ]; then
    log_error "This script must be run from within a git repository."
    exit 1
fi

log_info "Repository root: $REPO_ROOT"

# Check if host directory exists
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"

if [ ! -d "$HOST_DIR" ]; then
    log_error "Host directory not found: $HOST_DIR"
    log_info "Available hosts:"
    if [ -d "$REPO_ROOT/hosts" ]; then
        ls -1 "$REPO_ROOT/hosts" | sed 's/^/  - /'
    fi
    exit 1
fi

log_success "Found host directory: $HOST_DIR"

# Define key file paths
TEMPLATE_ENV="$HOST_DIR/template.env"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"

# Validate template exists
if [ ! -f "$TEMPLATE_ENV" ]; then
    log_error "Template environment file not found: $TEMPLATE_ENV"
    exit 1
fi

log_success "Found template environment file."

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

# Check for required commands
if ! command -v op &> /dev/null; then
    log_error "1Password CLI (op) is required but not installed."
    log_info "Install it from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Check if op is authenticated
if ! op account list &> /dev/null; then
    log_error "1Password CLI is not authenticated."
    log_info "Run: eval \$(op signin)"
    exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Step 2: Clean Existing .env File
# ------------------------------------------------------------------------
if [ -f "$GENERATED_ENV" ]; then
    log_warning "Generated .env file already exists: $GENERATED_ENV"
    echo -n "Overwrite? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Generation cancelled by user."
        exit 0
    fi
    
    log_info "Removing existing .env file..."
    rm -f "$GENERATED_ENV"
    log_success "Cleaned existing .env file."
fi

# ------------------------------------------------------------------------
# Step 3: Generate .env file from 1Password
# ------------------------------------------------------------------------
log_info "Generating .env file from 1Password secrets..."

# Create generated directory if it doesn't exist
mkdir -p "$GENERATED_DIR"

# Use 1Password CLI to inject secrets into .env file
if op inject -i "$TEMPLATE_ENV" -o "$GENERATED_ENV" 2>&1; then
    log_success "Generated .env file: $GENERATED_ENV"
else
    log_error "Failed to generate .env file using 1Password CLI."
    log_info "Ensure you are signed in to 1Password and have access to the secrets."
    exit 1
fi

# ------------------------------------------------------------------------
# Step 4: Final Summary
# ------------------------------------------------------------------------
log_info "Generated file:"
log_info "  • .env: $GENERATED_ENV"
echo ""

log_info "Next steps:"
log_info "1. Generate Nix configuration: ./dotfiles generate-nix-config $HOSTNAME"
log_info "2. Generate dotfiles: ./dotfiles generate-dotfiles $HOSTNAME"
script_footer "success"
