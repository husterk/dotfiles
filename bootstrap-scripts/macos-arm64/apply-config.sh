#!/usr/bin/env bash

# ========================================================================
# macOS ARM Apply Config Script
# ========================================================================
# This script applies a generated nix-darwin configuration by:
# - Copying generated/configuration.nix to the host directory
# - Temporarily staging it in git (required by nix flakes)
# - Running darwin-rebuild switch
# - Cleaning up the temporary file
#
# Usage: ./apply-config.sh [hostname]
# Example: ./apply-config.sh keith-macbook-pro
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load shared script helpers
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "Apply Nix Configuration" "Applies generated configuration and runs darwin-rebuild"

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
  REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2> /dev/null || echo "")

  if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/hosts" ]; then
    echo "Available hosts:"
    find "$REPO_ROOT/hosts" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  - /'
  fi

  exit 1
fi

log_info "Applying configuration for host: $HOSTNAME"

# Determine the git repo root directory
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2> /dev/null || echo "")

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
    find "$REPO_ROOT/hosts" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  - /'
  fi
  exit 1
fi

log_success "Found host directory: $HOST_DIR"

# Define key file paths
GENERATED_CONFIG="$HOST_DIR/generated/configuration.nix"
TEMP_CONFIG="$HOST_DIR/configuration.nix"

# Validate generated configuration exists
if [ ! -f "$GENERATED_CONFIG" ]; then
  log_error "Generated configuration not found: $GENERATED_CONFIG"
  log_info "Please run generate-nix-config.sh first to create the configuration."
  exit 1
fi

log_success "Found generated configuration: $GENERATED_CONFIG"

# ------------------------------------------------------------------------
# Step 1: Backup and Copy Configuration
# ------------------------------------------------------------------------
log_info "Preparing configuration for darwin-rebuild..."

# Check if temp location already exists and back it up
if [ -f "$TEMP_CONFIG" ]; then
  log_warning "Found existing configuration.nix, backing up..."
  cp "$TEMP_CONFIG" "$TEMP_CONFIG.backup"
  log_info "Backup saved to: $TEMP_CONFIG.backup"
fi

# Copy generated config to host directory
cp "$GENERATED_CONFIG" "$TEMP_CONFIG"
log_success "Copied configuration to: $TEMP_CONFIG"

# ------------------------------------------------------------------------
# Step 2: Stage Configuration in Git
# ------------------------------------------------------------------------
log_info "Staging configuration in git (required by nix flakes)..."

# Stage the file
git -C "$REPO_ROOT" add "$TEMP_CONFIG"
log_success "Configuration staged in git."

# ------------------------------------------------------------------------
# Step 3: Run darwin-rebuild
# ------------------------------------------------------------------------
log_info "Running darwin-rebuild switch..."
log_warning "This may take several minutes and will modify your system."
echo ""

# Run darwin-rebuild from the repo root
cd "$REPO_ROOT"

if sudo darwin-rebuild switch --impure --flake "./hosts/$HOSTNAME"; then
  log_success "darwin-rebuild completed successfully!"
else
  EXIT_CODE=$?
  log_error "darwin-rebuild failed with exit code: $EXIT_CODE"

  # Clean up even on failure
  log_info "Cleaning up temporary files..."
  git -C "$REPO_ROOT" reset HEAD "$TEMP_CONFIG" > /dev/null 2>&1
  rm -f "$TEMP_CONFIG"

  # Restore backup if it exists
  if [ -f "$TEMP_CONFIG.backup" ]; then
    mv "$TEMP_CONFIG.backup" "$TEMP_CONFIG"
    log_info "Restored original configuration.nix from backup."
  fi

  exit $EXIT_CODE
fi

# ------------------------------------------------------------------------
# Step 4: Cleanup
# ------------------------------------------------------------------------
log_info "Cleaning up temporary files..."

# Unstage the file
git -C "$REPO_ROOT" reset HEAD "$TEMP_CONFIG" > /dev/null 2>&1
log_info "Unstaged configuration from git."

# Remove the temporary file
rm -f "$TEMP_CONFIG"
log_info "Removed temporary configuration.nix"

# Remove backup if it exists
if [ -f "$TEMP_CONFIG.backup" ]; then
  rm -f "$TEMP_CONFIG.backup"
  log_info "Removed backup file."
fi

log_success "Cleanup complete."

# ------------------------------------------------------------------------
# Step 5: Final Summary
# ------------------------------------------------------------------------
log_info "Your system has been configured with nix-darwin."
log_info "The generated configuration remains at: $GENERATED_CONFIG"
log_info ""
log_info "Next steps:"
log_info "1. Restart your terminal to load new configurations"
log_info "2. Deploy dotfiles using stow if needed"
log_info "3. Review any warnings or messages from darwin-rebuild"
script_footer "success"
