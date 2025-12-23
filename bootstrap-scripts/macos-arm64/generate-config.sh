#!/bin/zsh

# ========================================================================
# macOS ARM Generate Config Script
# ========================================================================
# This script generates host-specific configuration and dotfiles by:
# - Using 1Password CLI to inject secrets into .env file
# - Generating configuration.nix with module imports from manifest
# - Generating dotfiles hierarchy with variable substitution
#
# Usage: ./generate-config.sh [hostname]
# Example: ./generate-config.sh keith-macbook-pro
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
TEMPLATE_ENV="$HOST_DIR/template.env"
CONFIG_TEMPLATE="$HOST_DIR/configuration-template.nix"
HOST_MANIFEST="$HOST_DIR/host-manifest.yml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"
GENERATED_CONFIG="$GENERATED_DIR/configuration.nix"
GENERATED_DOTFILES_DIR="$GENERATED_DIR/dotfiles"

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
# Step 2: Clean Generated Directory
# ------------------------------------------------------------------------
if [ -d "$GENERATED_DIR" ]; then
    log_warning "Generated directory already exists: $GENERATED_DIR"
    log_warning "All files in this directory will be deleted and regenerated."
    echo -n "Continue? (y/N): "
    read -r response
    
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Generation cancelled by user."
        exit 0
    fi
    
    log_info "Removing existing generated files..."
    rm -rf "$GENERATED_DIR"
    log_success "Cleaned generated directory."
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
# Step 3: Load environment variables from .env
# ------------------------------------------------------------------------
log_info "Loading environment variables from generated .env..."

# Source the .env file to load variables
if [ -f "$GENERATED_ENV" ]; then
    set -a  # automatically export all variables
    source "$GENERATED_ENV"
    set +a
    log_success "Environment variables loaded."
else
    log_error "Generated .env file not found: $GENERATED_ENV"
    exit 1
fi

# ------------------------------------------------------------------------
# Step 4: Parse host-manifest.yml and generate configuration.nix
# ------------------------------------------------------------------------
log_info "Generating configuration.nix from template and manifest..."

# Read configuration values from manifest
ROOT_RELATIVE_PATH=$(yq eval '.config.root-relative-path' "$HOST_MANIFEST")
HOME_DIR=$(yq eval '.config.home-dir' "$HOST_MANIFEST")

# Expand environment variables in HOME_DIR
HOME_DIR=$(echo "$HOME_DIR" | envsubst)

log_info "Root relative path: $ROOT_RELATIVE_PATH"
log_info "Home directory: $HOME_DIR"

# Extract system modules
SYSTEM_MODULES=$(yq eval '.system.modules[]' "$HOST_MANIFEST")
SYSTEM_COUNT=$(echo "$SYSTEM_MODULES" | grep -c . || echo "0")

# Extract app modules
APP_MODULES=$(yq eval '.apps[].modules[]' "$HOST_MANIFEST")
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
        module_path=$(echo "$module" | sed 's|^/||')
        echo "    $ROOT_RELATIVE_PATH$module_path"
    done > "$TEMP_SYSTEM"
fi
SYSTEM_FORMATTED=$(cat "$TEMP_SYSTEM")
rm "$TEMP_SYSTEM"

# Build the app modules list in proper Nix format
TEMP_APPS=$(mktemp)
if [ -n "$APP_MODULES" ]; then
    echo "$APP_MODULES" | while IFS= read -r module; do
        # Remove leading slash if present and combine with root relative path for apps
        module_path=$(echo "$module" | sed 's|^/||')
        echo "    $ROOT_RELATIVE_PATH$module_path"
    done > "$TEMP_APPS"
fi
APPS_FORMATTED=$(cat "$TEMP_APPS")
rm "$TEMP_APPS"

# Use awk to replace both placeholders
TEMP_CONFIG=$(mktemp)
awk -v system_modules="$SYSTEM_FORMATTED" -v app_modules="$APPS_FORMATTED" '
{
    if ($0 ~ /{{MANIFEST_SYSTEM_MODULES}}/) {
        print system_modules
    } else if ($0 ~ /{{MANIFEST_APPS_MODULES}}/) {
        print app_modules
    } else {
        print $0
    }
}
' "$GENERATED_CONFIG" > "$TEMP_CONFIG"

mv "$TEMP_CONFIG" "$GENERATED_CONFIG"

# Replace environment variable placeholders using envsubst
# Export all variables from .env so envsubst can use them
set -a
source "$GENERATED_ENV"
set +a

# Use envsubst to replace all ${VAR} placeholders
TEMP_CONFIG=$(mktemp)
envsubst < "$GENERATED_CONFIG" > "$TEMP_CONFIG"
mv "$TEMP_CONFIG" "$GENERATED_CONFIG"

log_success "Generated configuration.nix: $GENERATED_CONFIG"

# ------------------------------------------------------------------------
# Step 6: Generate dotfiles hierarchy
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
        
        # Replace ~ with the home directory from manifest config
        target="${target/\~/$HOME_DIR}"
        
        # Expand environment variables in target path
        TARGET_PATH=$(echo "$target" | envsubst)
        
        # Create relative path under generated/dotfiles preserving directory structure
        # Strip leading slash to make it relative
        RELATIVE_PATH="${TARGET_PATH#/}"
        
        DEST_PATH="$GENERATED_DOTFILES_DIR/$RELATIVE_PATH"
        
        # Create destination directory hierarchy
        mkdir -p "$(dirname "$DEST_PATH")"
        
        # Check if source file exists
        if [ ! -f "$SOURCE_PATH" ]; then
            log_warning "Source file not found: $SOURCE_PATH (skipping)"
            continue
        fi
        
        # Copy and substitute environment variables
        envsubst < "$SOURCE_PATH" > "$DEST_PATH"
        
        log_info "  ✓ Generated: $RELATIVE_PATH"
    done
    
    log_success "Generated dotfiles in: $GENERATED_DOTFILES_DIR"
fi

# ------------------------------------------------------------------------
# Step 7: Final Summary
# ------------------------------------------------------------------------
echo ""
log_success "=========================================="
log_success "Generation complete!"
log_success "=========================================="
echo ""

log_info "Generated files:"
log_info "  • .env file: $GENERATED_ENV"
log_info "  • configuration.nix: $GENERATED_CONFIG"
log_info "  • Dotfiles directory: $GENERATED_DOTFILES_DIR"
echo ""

log_info "Next steps:"
log_info "1. Review the generated configuration: $GENERATED_CONFIG"
log_info "2. Review the generated dotfiles in: $GENERATED_DOTFILES_DIR"
log_info "3. Apply configuration using: ./bootstrap-scripts/macos-arm64/apply-config.sh $HOSTNAME"
log_info "   (This script will temporarily stage the config, run darwin-rebuild, then clean up)"
log_info "   (Run from the repository root on the local machine, not the devcontainer)"
log_info "4. Deploy dotfiles using stow if needed"
echo ""
