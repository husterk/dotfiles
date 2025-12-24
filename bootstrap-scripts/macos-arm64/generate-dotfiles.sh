#!/bin/bash

# ========================================================================
# macOS ARM Generate Dotfiles Script
# ========================================================================
# This script generates host-specific dotfiles by:
# - Loading environment variables from generated .env file
# - Generating dotfiles hierarchy with variable substitution
# - Creating home-relative paths for GNU Stow compatibility
#
# Prerequisites: generate-nix-config.sh must be run first to create .env
#
# Usage: ./generate-dotfiles.sh [hostname]
# Example: ./generate-dotfiles.sh keith-macbook-pro
# ========================================================================

set -e  # Exit on error

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

log_info "Generating dotfiles for host: $HOSTNAME"

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
HOST_MANIFEST="$HOST_DIR/host-manifest.yml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"
GENERATED_DOTFILES_DIR="$GENERATED_DIR/dotfiles"

# Validate required files exist
if [ ! -f "$HOST_MANIFEST" ]; then
    log_error "Host manifest not found: $HOST_MANIFEST"
    exit 1
fi

if [ ! -f "$GENERATED_ENV" ]; then
    log_error "Generated .env file not found: $GENERATED_ENV"
    log_info "Please run generate-nix-config.sh first to create the .env file."
    exit 1
fi

log_success "All required files found."

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

if ! command -v yq &> /dev/null; then
    log_error "yq is required but not installed."
    log_info "Install it with: brew install yq"
    exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Step 2: Clean Generated Dotfiles Directory
# ------------------------------------------------------------------------
if [ -d "$GENERATED_DOTFILES_DIR" ]; then
    log_warning "Generated dotfiles directory already exists: $GENERATED_DOTFILES_DIR"
    log_warning "All files in this directory will be deleted and regenerated."
    echo -n "Continue? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Generation cancelled by user."
        exit 0
    fi
    
    log_info "Removing existing dotfiles..."
    rm -rf "$GENERATED_DOTFILES_DIR"
    log_success "Cleaned dotfiles directory."
fi

# ------------------------------------------------------------------------
# Step 3: Load environment variables from .env
# ------------------------------------------------------------------------
log_info "Loading environment variables from .env..."

# Source the .env file to load variables
if [ -f "$GENERATED_ENV" ]; then
    set -a  # automatically export all variables
    # shellcheck source=/dev/null
    source "$GENERATED_ENV"
    set +a
    log_success "Environment variables loaded."
    
    # Build envsubst variable list (only substitute vars from .env)
    ENVSUBST_VARS=$(grep -v '^#' "$GENERATED_ENV" | grep '=' | cut -d= -f1 | sed 's/^/$/' | tr '\n' ' ')
else
    log_error "Generated .env file not found: $GENERATED_ENV"
    exit 1
fi

# ------------------------------------------------------------------------
# Step 4: Generate dotfiles hierarchy
# ------------------------------------------------------------------------
log_info "Generating dotfiles hierarchy..."

# Create dotfiles directory
mkdir -p "$GENERATED_DOTFILES_DIR"

# Get count of dotfiles entries
DOTFILES_COUNT=$(yq eval '.apps[].dotfiles[]' "$HOST_MANIFEST" 2>/dev/null | grep -c "source:" || echo "0")

if [ "$DOTFILES_COUNT" -eq 0 ]; then
    log_warning "No dotfiles found in manifest."
else
    log_info "Processing $DOTFILES_COUNT dotfiles entries..."
    
    # Process each dotfile entry
    yq eval '.apps[] | select(.dotfiles != null) | .dotfiles[] | .source + "|" + .target' "$HOST_MANIFEST" | while IFS='|' read -r source target; do
        # Resolve source path (relative to REPO_ROOT)
        SOURCE_PATH="$REPO_ROOT$source"
        
        # Replace ~ with empty string to get home-relative path (for Stow compatibility)
        # Stow expects files to be relative to the target directory (home), not absolute paths
        target="${target/\~\//}"
        
        # Expand environment variables in target path (only from .env)
        TARGET_PATH=$(echo "$target" | envsubst "$ENVSUBST_VARS")
        
        # Use the target path directly as relative path (already home-relative)
        RELATIVE_PATH="$TARGET_PATH"
        
        DEST_PATH="$GENERATED_DOTFILES_DIR/$RELATIVE_PATH"
        
        # Create destination directory hierarchy
        mkdir -p "$(dirname "$DEST_PATH")"
        
        # Check if source file exists
        if [ ! -f "$SOURCE_PATH" ]; then
            log_warning "Source file not found: $SOURCE_PATH (skipping)"
            continue
        fi
        
        # Copy and substitute environment variables (only from .env)
        envsubst "$ENVSUBST_VARS" < "$SOURCE_PATH" > "$DEST_PATH"
        
        log_info "  ✓ Generated: $RELATIVE_PATH"
    done
    
    log_success "Generated dotfiles in: $GENERATED_DOTFILES_DIR"
fi

# ------------------------------------------------------------------------
# Step 5: Final Summary
# ------------------------------------------------------------------------
echo ""
log_success "=========================================="
log_success "Dotfiles Generated!"
log_success "=========================================="
echo ""

log_info "Generated files:"
log_info "  • Dotfiles directory: $GENERATED_DOTFILES_DIR"
echo ""

log_info "Next steps:"
log_info "1. Review the generated dotfiles in: $GENERATED_DOTFILES_DIR"
log_info "2. Deploy dotfiles using: ./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $HOSTNAME"
echo ""
