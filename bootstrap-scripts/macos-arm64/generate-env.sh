#!/usr/bin/env bash

# ========================================================================
# macOS ARM Generate Environment Script
# ========================================================================
# This script converts hosts/<hostname>/host-vars.toml into generated/.env,
# which the dotfile scripts source for envsubst.
#
# Usage: ./generate-env.sh <hostname>
# Example: ./generate-env.sh keith-macbook-pro
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
script_header "Generate Environment" "Creates .env file from host-vars.toml"

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

log_info "Generating .env file for host: $HOSTNAME"

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
HOST_VARS="$HOST_DIR/host-vars.toml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"

if [ ! -f "$HOST_VARS" ]; then
  log_error "Host variables file not found: $HOST_VARS"
  exit 1
fi

log_success "Found host variables file."

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

if ! command -v yq &> /dev/null; then
  log_error "yq is required but not installed."
  log_info "Run this script through mise: mise run env:generate"
  exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Step 2: Generate .env file from host-vars.toml
# ------------------------------------------------------------------------
log_info "Generating .env file from host-vars.toml..."

mkdir -p "$GENERATED_DIR"

# `-o shell` single-quotes any value that needs it, so the output is safe to
# source even when a value contains spaces, quotes, or `$`.
if yq -p toml -o shell '.' "$HOST_VARS" > "$GENERATED_ENV"; then
  log_success "Generated .env file: $GENERATED_ENV"
else
  log_error "Failed to convert $HOST_VARS to $GENERATED_ENV"
  exit 1
fi

# ------------------------------------------------------------------------
# Step 3: Final Summary
# ------------------------------------------------------------------------
log_info "Generated file:"
log_info "  • .env: $GENERATED_ENV"
echo ""

log_info "Next steps:"
log_info "1. Generate dotfiles: mise run dotfiles:generate"
log_info "2. Apply Nix configuration: mise run nix:apply"
script_footer "success"
