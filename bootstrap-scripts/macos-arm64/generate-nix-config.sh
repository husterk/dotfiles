#!/usr/bin/env bash

# ========================================================================
# macOS ARM Generate Nix Config Script
# ========================================================================
# This script generates host-specific nix-darwin configuration by:
# - Using 1Password CLI to inject secrets into .env file
# - Generating configuration.nix with module imports from manifest
#
# Usage: ./generate-nix-config.sh [hostname]
# Example: ./generate-nix-config.sh keith-macbook-pro
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

# Default configuration
FORCE_OVERWRITE="${FORCE_OVERWRITE:-false}"

# Display script header
script_header "Generate Nix Configuration" "Creates configuration.nix from template and manifest"

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

log_info "Generating nix configuration for host: $HOSTNAME"

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
TEMPLATE_ENV="$HOST_DIR/template.env"
CONFIG_TEMPLATE="$HOST_DIR/configuration-template.nix"
HOST_MANIFEST="$HOST_DIR/host-manifest.yml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"
GENERATED_CONFIG="$GENERATED_DIR/configuration.nix"

# Validate required files exist
if [ ! -f "$TEMPLATE_ENV" ]; then
  log_error "Template environment file not found: $TEMPLATE_ENV"
  exit 1
fi

if [ ! -f "$CONFIG_TEMPLATE" ]; then
  log_error "Configuration template not found: $CONFIG_TEMPLATE"
  exit 1
fi

if [ ! -f "$HOST_MANIFEST" ]; then
  log_error "Host manifest not found: $HOST_MANIFEST"
  exit 1
fi

log_success "All required template files found."

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

if ! command -v yq &> /dev/null; then
  log_error "yq is required but not installed."
  log_info "Install it with: brew install yq"
  exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Step 2: Check for existing .env file
# ------------------------------------------------------------------------
if [ -f "$GENERATED_ENV" ]; then
  log_info "Using existing .env file: $GENERATED_ENV"
  log_info "To regenerate .env from 1Password, run: mise run env:generate"
else
  log_info "No .env file found. Generating from 1Password..."

  # Create generated directory if it doesn't exist
  mkdir -p "$GENERATED_DIR"

  # Use 1Password CLI to inject secrets into .env file
  if op inject -i "$TEMPLATE_ENV" -o "$GENERATED_ENV" 2>&1; then
    log_success "Generated .env file: $GENERATED_ENV"
  else
    log_error "Failed to generate .env file using 1Password CLI."
    log_info "Ensure you are signed in to 1Password and have access to the secrets."
    log_info "Or run: mise run env:generate"
    exit 1
  fi
fi

# ------------------------------------------------------------------------
# Step 3: Clean Existing Configuration File
# ------------------------------------------------------------------------
if [ -f "$GENERATED_CONFIG" ]; then
  log_warning "Generated configuration file already exists: $GENERATED_CONFIG"
  echo -n "Overwrite? (y/N): "
  read -r response

  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "Generation cancelled by user."
    exit 0
  fi

  log_info "Removing existing configuration file..."
  rm -f "$GENERATED_CONFIG"
  log_success "Cleaned existing configuration file."
fi

# ------------------------------------------------------------------------
# Step 4: Load environment variables from .env
# ------------------------------------------------------------------------
log_info "Loading environment variables from generated .env..."

# Source the .env file to load variables
if [ -f "$GENERATED_ENV" ]; then
  set -a # automatically export all variables
  # shellcheck source=/dev/null
  source "$GENERATED_ENV"
  set +a
  log_success "Environment variables loaded."
else
  log_error "Generated .env file not found: $GENERATED_ENV"
  exit 1
fi

# ------------------------------------------------------------------------
# Step 5: Parse host-manifest.yml and generate configuration.nix
# ------------------------------------------------------------------------
log_info "Generating configuration.nix from template and manifest..."

# Read configuration values from manifest
ROOT_RELATIVE_PATH=$(yq eval -r '.config.root-relative-path' "$HOST_MANIFEST")
HOME_DIR=$(yq eval -r '.config.home-dir' "$HOST_MANIFEST")

# Expand environment variables in HOME_DIR
HOME_DIR=$(echo "$HOME_DIR" | envsubst)

log_info "Root relative path: $ROOT_RELATIVE_PATH"
log_info "Home directory: $HOME_DIR"

# Extract system modules
SYSTEM_MODULES=$(yq eval -r '.system.modules[]' "$HOST_MANIFEST")
SYSTEM_COUNT=$(echo "$SYSTEM_MODULES" | grep -c . || echo "0")

# Extract app modules
APP_MODULES=$(yq eval -r '.apps[].modules[]' "$HOST_MANIFEST")
APP_COUNT=$(echo "$APP_MODULES" | grep -c . || echo "0")

TOTAL_COUNT=$((SYSTEM_COUNT + APP_COUNT))
log_info "Found $TOTAL_COUNT modules to import ($SYSTEM_COUNT system, $APP_COUNT apps)."

# Copy template to generated location
cp "$CONFIG_TEMPLATE" "$GENERATED_CONFIG"

# Build the system modules list in proper Nix format
TEMP_SYSTEM=$(mktemp)
if [ -n "$SYSTEM_MODULES" ]; then
  echo "$SYSTEM_MODULES" | while IFS= read -r module; do
    # Remove leading slash if present and combine with root relative path for modules
    module_path="${module#/}"
    echo "    $ROOT_RELATIVE_PATH$module_path"
  done > "$TEMP_SYSTEM"
fi

# Build the app modules list in proper Nix format
TEMP_APPS=$(mktemp)
if [ -n "$APP_MODULES" ]; then
  echo "$APP_MODULES" | while IFS= read -r module; do
    # Remove leading slash if present and combine with root relative path for apps
    module_path="${module#/}"
    echo "    $ROOT_RELATIVE_PATH$module_path"
  done > "$TEMP_APPS"
fi

# Use sed to replace both placeholders (comment-based format)
# First replace system modules
sed -i.bak "/#{{MANIFEST_SYSTEM_MODULES}}/r $TEMP_SYSTEM" "$GENERATED_CONFIG"
sed -i.bak "/#{{MANIFEST_SYSTEM_MODULES}}/d" "$GENERATED_CONFIG"

# Then replace app modules
sed -i.bak "/#{{MANIFEST_APPS_MODULES}}/r $TEMP_APPS" "$GENERATED_CONFIG"
sed -i.bak "/#{{MANIFEST_APPS_MODULES}}/d" "$GENERATED_CONFIG"

# Clean up temp files and backup
rm -f "$TEMP_SYSTEM" "$TEMP_APPS" "${GENERATED_CONFIG}.bak"

# Replace environment variable placeholders using envsubst
# Export all variables from .env so envsubst can use them
set -a
# shellcheck source=/dev/null
source "$GENERATED_ENV"
set +a

# Use envsubst to replace all ${VAR} placeholders
TEMP_CONFIG=$(mktemp)
envsubst < "$GENERATED_CONFIG" > "$TEMP_CONFIG"
mv "$TEMP_CONFIG" "$GENERATED_CONFIG"

log_success "Generated configuration.nix: $GENERATED_CONFIG"

# ------------------------------------------------------------------------
# Step 6: Final Summary
# ------------------------------------------------------------------------
log_info "Generated files:"
log_info "  • .env file: $GENERATED_ENV"
log_info "  • configuration.nix: $GENERATED_CONFIG"
echo ""

log_info "Next steps:"
log_info "1. Review the generated configuration: $GENERATED_CONFIG"
log_info "2. Apply configuration using: ./bootstrap-scripts/macos-arm64/apply-config.sh $HOSTNAME"
log_info "   (This script will temporarily stage the config, run darwin-rebuild, then clean up)"
script_footer "success"
