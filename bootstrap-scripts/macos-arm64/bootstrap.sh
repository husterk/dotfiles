#!/usr/bin/env bash

# ========================================================================
# macOS ARM Bootstrap Script
# ========================================================================
# This script bootstraps a macOS system with:
# - Nix package manager (using Determinate Systems installer)
# - nix-darwin (declarative macOS configuration)
# - GNU Stow (dotfiles management)
#
# The script is fully idempotent and can be safely run multiple times
# to bootstrap new systems or update existing ones.
#
# Usage: ./bootstrap.sh <hostname>
# Example: ./bootstrap.sh keith-macbook-pro
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
script_header "macOS ARM Bootstrap" "Installs Nix, nix-darwin, and GNU Stow"

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

# Check for required commands
if ! command -v curl &> /dev/null; then
  log_error "curl is required but not installed. Please install curl and re-run this script."
  exit 1
fi

if ! command -v git &> /dev/null; then
  log_error "git is required but not installed. Please install git and re-run this script."
  exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Step 0: Parse Arguments
# ------------------------------------------------------------------------
HOSTNAME="${1:-}"

if [ -z "$HOSTNAME" ]; then
  log_error "No hostname provided."
  echo ""
  echo "Usage: $0 <hostname>"
  echo ""
  echo "Example: $0 keith-macbook-pro"
  exit 1
fi

log_info "Bootstrapping host: $HOSTNAME"

# ------------------------------------------------------------------------
# Step 2: Install Nix Package Manager
# ------------------------------------------------------------------------
log_info "Installing Nix package manager..."

# Check if Nix is already installed by looking for /nix directory and receipt
if [ ! -d "/nix" ] || [ ! -f "/nix/receipt.json" ]; then
  log_info "Nix not found. Installing via Determinate Systems installer..."
  # Use --prefer-upstream-nix flag for vanilla Nix (not Determinate distribution)
  # This allows nix-darwin to manage Nix settings
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --prefer-upstream-nix

  log_success "Nix installation complete."
else
  log_success "Nix is already installed."
fi

# Always source nix profile to make 'nix' available in current session
if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck source=/dev/null
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Verify Nix is now available
if ! command -v nix &> /dev/null; then
  log_error "Nix installation failed or is not in PATH."
  log_info "Please restart your shell and re-run this script."
  exit 1
fi

# ------------------------------------------------------------------------
# Step 3: Enable Nix Experimental Features
# ------------------------------------------------------------------------
log_info "Configuring Nix experimental features..."

# Function to check if a feature is enabled in nix.conf
has_nix_feature() {
  local feature="$1"
  local conf_file="$2"
  [ -f "$conf_file" ] && grep -q "experimental-features.*$feature" "$conf_file"
}

# Function to ensure experimental feature is present in nix.conf
ensure_nix_feature() {
  local feature="$1"
  local conf_file="$2"

  if ! has_nix_feature "$feature" "$conf_file"; then
    log_info "Adding experimental feature: $feature"
    if grep -q "^experimental-features" "$conf_file" 2> /dev/null; then
      # Line exists, append the feature
      sed -i '' "s/^experimental-features = \(.*\)/experimental-features = \1 $feature/" "$conf_file"
    else
      # Line doesn't exist, create it
      echo "experimental-features = $feature" >> "$conf_file"
    fi
  else
    log_info "Experimental feature '$feature' already enabled."
  fi
}

# Ensure config directory and file exist
mkdir -p ~/.config/nix
touch ~/.config/nix/nix.conf

# Ensure both required features are enabled
ensure_nix_feature "nix-command" ~/.config/nix/nix.conf
ensure_nix_feature "flakes" ~/.config/nix/nix.conf

log_success "Nix experimental features configured."

# ------------------------------------------------------------------------
# Step 4: Setup Configuration Repository
# ------------------------------------------------------------------------
log_info "Checking configuration repository..."

# Determine the git repo root directory
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2> /dev/null || echo "")

if [ -z "$REPO_ROOT" ]; then
  log_error "This script must be run from within a git repository."
  log_info "Please ensure this script is in your dotfiles repository."
  exit 1
fi

log_info "Repository root: $REPO_ROOT"

# Check if the host configuration exists
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"
HOST_CONFIG="$HOST_DIR/configuration.nix"

if [ ! -f "$HOST_CONFIG" ]; then
  log_warning "No configuration.nix found for host '$HOSTNAME' at: $HOST_CONFIG"
  log_info "Available hosts:"
  if [ -d "$REPO_ROOT/hosts" ]; then
    for dir in "$REPO_ROOT/hosts"/*; do
      if [ -d "$dir" ]; then
        basename "$dir"
      fi
    done | grep -v "^README$" | sed 's/^/  - /'
  fi
  log_info ""
  log_info "Please create a host configuration:"
  log_info "  mkdir -p $HOST_DIR"
  log_info "  # Create $HOST_CONFIG, host-manifest.toml and host-vars.toml"
  log_info "See: https://github.com/nix-darwin/nix-darwin#flakes"
  SKIP_DARWIN=true
else
  log_success "Found configuration for host '$HOSTNAME'."
  SKIP_DARWIN=false
fi

# ------------------------------------------------------------------------
# Step 5: Install nix-darwin
# ------------------------------------------------------------------------
if [ "$SKIP_DARWIN" = false ]; then
  log_info "Setting up nix-darwin..."

  # Check if darwin-rebuild is already available
  if command -v darwin-rebuild &> /dev/null; then
    log_success "nix-darwin is already installed."
  else
    log_info "Installing nix-darwin for the first time..."

    log_info "Using host configuration at: $HOST_DIR"

    # Check for conflicting files that nix-darwin manages
    CONFLICTS=()
    [ -f /etc/zshrc ] && CONFLICTS+=("/etc/zshrc")
    [ -f /etc/zshenv ] && CONFLICTS+=("/etc/zshenv")
    [ -f /etc/bashrc ] && CONFLICTS+=("/etc/bashrc")
    [ -f /etc/nix/nix.conf ] && CONFLICTS+=("/etc/nix/nix.conf")

    if [ ${#CONFLICTS[@]} -gt 0 ]; then
      log_warning "Found system files that may conflict with nix-darwin:"
      for file in "${CONFLICTS[@]}"; do
        log_warning "  - $file"
      done

      log_info "Backing up conflicting files..."
      for file in "${CONFLICTS[@]}"; do
        if [ -f "$file" ]; then
          sudo mv "$file" "${file}.before-nix-darwin"
          log_info "  Backed up: $file -> ${file}.before-nix-darwin"
        fi
      done
    fi

    # Run the initial nix-darwin switch
    log_info "Running initial nix-darwin build..."
    log_info "This may take several minutes on first run..."

    # Run nix-darwin switch with the repo-root flake (requires sudo for system activation)
    # Pass experimental features since root user doesn't inherit user config
    if sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "$REPO_ROOT#$HOSTNAME" 2>&1; then
      log_success "nix-darwin installed and activated successfully!"
    else
      log_error "Failed to install nix-darwin."
      log_info "Please check your host configuration at: $HOST_CONFIG"
      log_info "See: https://github.com/nix-darwin/nix-darwin for documentation."
      exit 1
    fi
  fi

  # Verify nix-darwin installation
  if command -v darwin-rebuild &> /dev/null; then
    log_success "nix-darwin is ready."
  fi
else
  log_warning "Skipping nix-darwin installation (no host configuration found)."
fi

# ------------------------------------------------------------------------
# Step 6: Setup GNU Stow for Dotfiles
# ------------------------------------------------------------------------
log_info "Setting up GNU Stow..."

# Check if stow is available (might be installed via nix-darwin)
if command -v stow &> /dev/null; then
  log_success "GNU Stow is already available ($(stow --version | head -n1))."
else
  log_warning "GNU Stow not found in PATH."

  # If nix-darwin was installed, suggest adding stow to configuration
  if [ "$SKIP_DARWIN" = false ]; then
    log_info "Add 'stow' to your nix-darwin configuration's environment.systemPackages"
    log_info "Then run: darwin-rebuild switch --flake $REPO_ROOT#$HOSTNAME"
  else
    log_info "Install stow manually or add it to your Nix configuration."
  fi
fi

# If stow is available and we have a dotfiles directory, offer to stow
if command -v stow &> /dev/null && [ -d "$REPO_ROOT/dotfiles" ]; then
  log_info "Dotfiles directory found: $REPO_ROOT/dotfiles"
  log_info "To stow your dotfiles, run:"
  log_info "  cd $REPO_ROOT/dotfiles && stow *"
  log_info "Or stow individual packages:"
  log_info "  cd $REPO_ROOT/dotfiles && stow <package-name>"
fi

# ------------------------------------------------------------------------
# Step 7: Final Instructions
# ------------------------------------------------------------------------
if [ "$SKIP_DARWIN" = false ]; then
  log_info "Next steps:"
  log_info "1. Review your nix-darwin configuration in $HOST_DIR"
  log_info "2. Make any desired changes to your system configuration"
  log_info "3. Apply changes with: mise run nix:apply"
  if command -v stow &> /dev/null && [ -d "$REPO_ROOT/dotfiles" ]; then
    log_info "4. Stow your dotfiles: cd $REPO_ROOT/dotfiles && stow <packages>"
  fi
else
  log_info "To complete setup:"
  log_info "1. Create a host directory: mkdir -p $HOST_DIR"
  log_info "2. Create $HOST_CONFIG, host-manifest.toml and host-vars.toml"
  log_info "3. Re-run this script to install nix-darwin"
  log_info "4. See: https://github.com/nix-darwin/nix-darwin#getting-started"
fi

log_info "You may need to restart your shell or terminal for all changes to take effect."
script_footer "success"
