#!/usr/bin/env bash

# ========================================================================
# nix-darwin Helper Script
# ========================================================================
# This script provides convenient shortcuts for low-level nix-darwin operations.
# Use this for direct darwin-rebuild commands without the full workflow.
#
# For high-level operations, use mise instead (e.g., mise run nix:apply).
#
# Usage: ./darwin-helper.sh <command> <hostname>
# ========================================================================

set -e

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load shared script helpers
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "nix-darwin Helper" "Low-level darwin-rebuild operations"

# Parse arguments
COMMAND="${1:-}"
HOSTNAME="${2:-}"

if [ -z "$COMMAND" ]; then
  log_error "No command provided."
  echo ""
  echo "Usage: $0 <command> <hostname>"
  echo "Example: $0 switch keith-macbook-pro"
  exit 1
fi

if [ -z "$HOSTNAME" ]; then
  log_error "No hostname provided."
  echo ""
  echo "Usage: $0 <command> <hostname>"
  echo "Example: $0 switch keith-macbook-pro"
  exit 1
fi

# Get the repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2> /dev/null || echo ".")

# Host-specific directory and flake path
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"
FLAKE_PATH="$HOST_DIR/flake.nix"

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

  help | --help | -h)
    show_help
    ;;

  *)
    log_error "Unknown command: $COMMAND"
    echo ""
    show_help
    exit 1
    ;;
esac

script_footer "success"
