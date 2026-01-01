#!/usr/bin/env bash

# ========================================================================
# macOS ARM Unbootstrap Script
# ========================================================================
# This script removes nix and nix-darwin from a macOS system.
# WARNING: This will remove all nix-darwin configurations and Nix packages!
#
# Usage: ./unbootstrap.sh <hostname>
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
script_header "Unbootstrap macOS" "WARNING: Removes Nix and nix-darwin from system"

# ------------------------------------------------------------------------
# Validate Hostname
# ------------------------------------------------------------------------
EXPECTED_HOSTNAME="$1"

if [ -z "$EXPECTED_HOSTNAME" ]; then
  log_error "Hostname is required."
  echo "Usage: $0 <hostname>"
  exit 1
fi

CURRENT_HOSTNAME=$(hostname -s 2> /dev/null || hostname 2> /dev/null)

if [ "$CURRENT_HOSTNAME" != "$EXPECTED_HOSTNAME" ]; then
  log_error "Hostname mismatch!"
  log_error "Expected: $EXPECTED_HOSTNAME"
  log_error "Current:  $CURRENT_HOSTNAME"
  log_error "This script can only be run on the correct host."
  exit 1
fi

log_info "Hostname verified: $CURRENT_HOSTNAME"

# ------------------------------------------------------------------------
# Step 1: Confirm Uninstall
# ------------------------------------------------------------------------
echo ""
log_warning "=========================================="
log_warning "WARNING: Nix Uninstall"
log_warning "=========================================="
echo ""
log_warning "This will completely remove:"
log_warning "  • nix-darwin and all system configurations"
log_warning "  • Nix package manager and all installed packages"
log_warning "  • All data in /nix directory"
echo ""
log_warning "This action CANNOT be undone!"
echo ""
echo -n "Are you sure you want to continue? Type 'yes' to proceed: "
read -r response

if [ "$response" != "yes" ]; then
  log_info "Uninstall cancelled."
  exit 0
fi

# ------------------------------------------------------------------------
# Step 2: Uninstall nix-darwin (if installed)
# ------------------------------------------------------------------------
log_info "Checking for nix-darwin installation..."

if [ -f "/nix/receipt.json" ] && command -v darwin-rebuild &> /dev/null; then
  log_info "Found nix-darwin installation. Uninstalling..."

  # Try to uninstall nix-darwin
  if sudo nix-darwin uninstaller 2> /dev/null || sudo /nix/nix-installer uninstall 2> /dev/null; then
    log_success "nix-darwin uninstalled."
  else
    log_warning "Could not uninstall nix-darwin (may not be installed or already removed)."
  fi
else
  log_info "nix-darwin not found or not installed."
fi

# ------------------------------------------------------------------------
# Step 3: Uninstall Nix
# ------------------------------------------------------------------------
log_info "Uninstalling Nix package manager..."

# Check if Nix is installed
if [ ! -d "/nix" ]; then
  log_info "Nix directory /nix not found. Nix may already be uninstalled."
else
  # Try Determinate Systems uninstaller first
  if [ -f "/nix/nix-installer" ]; then
    log_info "Using Determinate Systems uninstaller..."
    if sudo /nix/nix-installer uninstall; then
      log_success "Nix uninstalled successfully."
    else
      log_error "Determinate Systems uninstaller failed."
    fi
  else
    # Fallback to manual uninstall
    log_warning "No automatic uninstaller found. Performing manual cleanup..."

    # Stop nix-daemon if running
    if sudo launchctl list | grep -q nix-daemon; then
      log_info "Stopping nix-daemon..."
      sudo launchctl unload /Library/LaunchDaemons/org.nixos.nix-daemon.plist 2> /dev/null || true
    fi

    # Remove nix-daemon launchd plist
    if [ -f "/Library/LaunchDaemons/org.nixos.nix-daemon.plist" ]; then
      log_info "Removing nix-daemon launchd configuration..."
      sudo rm -f /Library/LaunchDaemons/org.nixos.nix-daemon.plist
    fi

    # Remove nix directory
    log_info "Removing /nix directory..."
    sudo rm -rf /nix

    # Remove nix users and group
    log_info "Removing nix users and group..."
    for u in $(sudo dscl . -list /Users | grep nixbld); do
      sudo dscl . -delete "/Users/$u" 2> /dev/null || true
    done
    sudo dscl . -delete /Groups/nixbld 2> /dev/null || true

    # Remove nix volume entry from /etc/fstab (if present)
    if grep -q "nix" /etc/fstab 2> /dev/null; then
      log_info "Removing nix entry from /etc/fstab..."
      sudo sed -i.backup '/nix/d' /etc/fstab 2> /dev/null || true
    fi

    # Remove nix from /etc/synthetic.conf (if present)
    if [ -f "/etc/synthetic.conf" ] && grep -q "^nix" /etc/synthetic.conf; then
      log_info "Removing nix from /etc/synthetic.conf..."
      sudo sed -i.backup '/^nix/d' /etc/synthetic.conf 2> /dev/null || true
    fi

    log_success "Manual Nix cleanup complete."
  fi
fi

# ------------------------------------------------------------------------
# Step 4: Clean up shell profiles
# ------------------------------------------------------------------------
log_info "Cleaning up shell profile configurations..."

PROFILES=(
  "$HOME/.bash_profile"
  "$HOME/.bashrc"
  "$HOME/.zshrc"
  "$HOME/.zprofile"
)

for profile in "${PROFILES[@]}"; do
  if [ -f "$profile" ]; then
    # Remove nix-daemon sourcing lines
    if grep -q "nix-daemon.sh" "$profile"; then
      log_info "Removing Nix configuration from: $profile"
      sed -i.backup '/nix-daemon.sh/d' "$profile" 2> /dev/null || true
    fi
  fi
done

log_success "Shell profiles cleaned."

# ------------------------------------------------------------------------
# Step 5: Final Summary
# ------------------------------------------------------------------------
log_info "Nix and nix-darwin have been removed from your system."
log_info ""
log_info "Next steps:"
log_info "1. Restart your terminal to complete the cleanup"
log_info "2. Optionally review backup files in your home directory (*.backup)"
log_info "3. You may need to restart your computer to complete volume cleanup"
script_footer "success"
