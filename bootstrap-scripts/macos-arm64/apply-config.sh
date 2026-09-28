#!/usr/bin/env bash

# ========================================================================
# macOS ARM Apply Config Script
# ========================================================================
# This script applies the nix-darwin configuration for a host by running
# darwin-rebuild switch against the repo-root flake. When a private overlay
# clone exists, it replaces the flake's `private` input for this run only.
#
# Usage: ./apply-config.sh [hostname]
# Example: ./apply-config.sh keith-macbook-pro
# ========================================================================

set -euo pipefail

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load shared script helpers
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "Apply Nix Configuration" "Runs darwin-rebuild switch for this host"

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

PRIVATE_DIR="${DOTFILES_PRIVATE_DIR:-$HOME/git-repos/dotfiles-private}"

if [ ! -f "$HOST_DIR/configuration.nix" ]; then
  log_error "Host configuration not found: $HOST_DIR/configuration.nix"
  exit 1
fi

# ------------------------------------------------------------------------
# Step 1: Resolve the private input
# ------------------------------------------------------------------------
# --override-input implies --no-write-lock-file, so flake.lock keeps pointing
# at the tracked stub. The flag is passed explicitly anyway.
PRIVATE_FLAGS=()
if [ -f "$PRIVATE_DIR/default.nix" ]; then
  log_success "Using private overlay: $PRIVATE_DIR"
  # Nix rejects a path: input that passes through a symlink, so resolve it.
  PRIVATE_FLAGS=(--override-input private "path:$(cd "$PRIVATE_DIR" && pwd -P)" --no-write-lock-file)
elif [ "${ALLOW_PUBLIC_STUB:-}" = "1" ]; then
  log_warning "ALLOW_PUBLIC_STUB=1: applying without the private overlay."
else
  log_error "Private overlay not found at $PRIVATE_DIR."
  log_info "Clone it: gh repo clone husterk/dotfiles-private \"$PRIVATE_DIR\""
  log_info "A fresh machine with nothing private installed can set ALLOW_PUBLIC_STUB=1."
  exit 1
fi

# ------------------------------------------------------------------------
# Step 2: Run darwin-rebuild
# ------------------------------------------------------------------------
log_info "Running darwin-rebuild switch..."
log_warning "This may take several minutes and will modify your system."
echo ""

if sudo darwin-rebuild switch --flake "$REPO_ROOT#$HOSTNAME" ${PRIVATE_FLAGS[@]+"${PRIVATE_FLAGS[@]}"}; then
  log_success "darwin-rebuild completed successfully!"
else
  EXIT_CODE=$?
  log_error "darwin-rebuild failed with exit code: $EXIT_CODE"
  exit $EXIT_CODE
fi

# ------------------------------------------------------------------------
# Step 3: Final Summary
# ------------------------------------------------------------------------
log_info "Your system has been configured with nix-darwin."
log_info ""
log_info "Next steps:"
log_info "1. Restart your terminal to load new configurations"
log_info "2. Deploy dotfiles using stow if needed"
log_info "3. Review any warnings or messages from darwin-rebuild"
script_footer "success"
