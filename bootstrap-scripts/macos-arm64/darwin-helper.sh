#!/bin/bash

# ========================================================================
# nix-darwin Helper Script
# ========================================================================
# This script provides convenient shortcuts for common nix-darwin operations
# ========================================================================

set -e

# Get the repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")

# Get the hostname
HOSTNAME=$(hostname -s)

# Host-specific directory and flake path
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"
FLAKE_PATH="$HOST_DIR/flake.nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

show_help() {
    cat << EOF
nix-darwin Helper Script

Usage: $(basename "$0") [COMMAND]

Commands:
  switch      Build and activate configuration (requires sudo)
  build       Build configuration without activating
  check       Check flake.nix for errors
  update      Update flake inputs
  upgrade     Update inputs and rebuild system
  rollback    Rollback to previous generation
  list        List system generations
  clean       Clean old generations (keeps last 7 days)
  edit        Edit flake.nix
  help        Show this help message

Current host: $HOSTNAME
Flake path: $HOST_DIR

Examples:
  $(basename "$0") switch    # Apply configuration changes
  $(basename "$0") build     # Test build without applying
  $(basename "$0") update    # Update package versions
  $(basename "$0") rollback  # Undo last changes

EOF
}

# Check if we're in the repo and host configuration exists
if [ ! -f "$FLAKE_PATH" ]; then
    log_error "No flake.nix found for host '$HOSTNAME' at: $FLAKE_PATH"
    log_info "Available hosts:"
    if [ -d "$REPO_ROOT/hosts" ]; then
        for dir in "$REPO_ROOT/hosts"/*; do
            if [ -d "$dir" ]; then
                basename "$dir"
            fi
        done | grep -v "^README$" | sed 's/^/  - /'
    fi
    log_info ""
    log_info "Create a host configuration at: $HOST_DIR"
    exit 1
fi

# Parse command
COMMAND="${1:-help}"

case "$COMMAND" in
    switch)
        log_info "Building and activating configuration for host '$HOSTNAME'..."
        darwin-rebuild switch --flake "$HOST_DIR"
        log_success "System configuration activated!"
        ;;
    
    build)
        log_info "Building configuration (no activation)..."
        darwin-rebuild build --flake "$HOST_DIR"
        log_success "Build successful!"
        ;;
    
    check)
        log_info "Checking flake.nix for errors..."
        nix flake check "$HOST_DIR"
        log_success "No errors found!"
        ;;
    
    update)
        log_info "Updating flake inputs..."
        nix flake update "$HOST_DIR"
        log_success "Flake inputs updated!"
        log_info "Run '$(basename "$0") switch' to apply updates"
        ;;
    
    upgrade)
        log_info "Updating flake inputs..."
        nix flake update "$HOST_DIR"
        log_info "Rebuilding system with updated inputs..."
        darwin-rebuild switch --flake "$HOST_DIR"
        log_success "System upgraded!"
        ;;
    
    rollback)
        log_info "Rolling back to previous generation..."
        darwin-rebuild --rollback
        log_success "Rolled back to previous generation!"
        ;;
    
    list)
        log_info "System generations:"
        nix profile history --profile /nix/var/nix/profiles/system
        ;;
    
    clean)
        log_info "Cleaning old generations (keeping last 7 days)..."
        sudo nix-collect-garbage --delete-older-than 7d
        log_success "Old generations cleaned!"
        ;;
    
    edit)
        ${EDITOR:-vim} "$FLAKE_PATH"
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        log_error "Unknown command: $COMMAND"
        echo ""
        show_help
        exit 1
        ;;
esac
