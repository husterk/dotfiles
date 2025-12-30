#!/bin/bash

# ========================================================================
# Configure macOS Dock
# ========================================================================
# This script configures the macOS Dock with a predefined set of applications.
# It removes all existing Dock items and adds specified applications.
#
# Usage: configure-dock.sh <users-path> <username> <dockutil-path>
# Example: configure-dock.sh /Users keithhuster /opt/homebrew/bin/dockutil
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers (skip if already sourced by parent)
if ! command -v script_header &>/dev/null; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/script-helpers.sh"
fi

# Display script header
script_header "Configure macOS Dock" "Removes all items and adds predefined applications"

# ------------------------------------------------------------------------
# Validate Input Parameters
# ------------------------------------------------------------------------

if [ $# -ne 3 ]; then
  log_error "Invalid number of arguments."
  echo ""
  echo "Usage: $0 <users-path> <username> <dockutil-path>"
  echo "Example: $0 /Users keithhuster /opt/homebrew/bin/dockutil"
  exit 1
fi

usersPath="${1}"
username="${2}"
dockutilPath="${3}"
userHomePath="${usersPath}/${username}"

# Validate username exists
if ! id "${username}" &>/dev/null; then
  log_error "User '${username}' does not exist."
  exit 1
fi

# Validate user home directory exists
if [ ! -d "${userHomePath}" ]; then
  log_error "User home directory '${userHomePath}' does not exist."
  exit 1
fi

# Validate dockutil exists
if [ ! -f "${dockutilPath}" ]; then
  log_error "dockutil not found at '${dockutilPath}'."
  log_info "Install dockutil via Homebrew: brew install dockutil"
  exit 1
fi

# ------------------------------------------------------------------------
# Define Dock Applications
# ------------------------------------------------------------------------

# Define applications to add to Dock (in order)
declare -a DOCK_APPS=(
  "/Applications/Google Chrome.app"
  "/System/Applications/Messages.app"
  "/Applications/Visual Studio Code.app"
  "/Applications/Nix Apps/WezTerm.app"
  "/Applications/1Password.app"
  "/Applications/Davinci Resolve.app"
  "/Applications/Insta360 Studio.app"
  "/System/Applications/Notes.app"
  "/System/Applications/Stickies.app"
)

# ------------------------------------------------------------------------
# Configure Dock
# ------------------------------------------------------------------------

log_info "Configuring Dock for ${username}..."
echo ""

# Get current dock items
log_info "Checking current Dock configuration..."
CURRENT_DOCK=$(sudo -u "${username}" "${dockutilPath}" --list "${userHomePath}" 2>/dev/null | grep -E '^\s+file:///') || true

# Check if we need to make changes
NEEDS_UPDATE=false

# Count expected apps (only those that exist)
EXPECTED_COUNT=0
for app in "${DOCK_APPS[@]}"; do
  if [ -e "${app}" ]; then
    EXPECTED_COUNT=$((EXPECTED_COUNT + 1))
    # Check if this app is in the current dock at the correct position
    if ! echo "${CURRENT_DOCK}" | grep -qF "${app}"; then
      NEEDS_UPDATE=true
      break
    fi
  fi
done

# Count current dock items
CURRENT_COUNT=$(echo "${CURRENT_DOCK}" | grep -c 'file:///' || echo "0")

# If counts don't match, we need to update
if [ "${CURRENT_COUNT}" -ne "${EXPECTED_COUNT}" ]; then
  NEEDS_UPDATE=true
fi

if [ "${NEEDS_UPDATE}" = false ]; then
  log_success "Dock is already configured correctly."
  echo ""
  log_success "=========================================="
  log_success "Dock configuration complete!"
  log_success "=========================================="
  exit 0
fi

log_info "Dock needs updating..."
echo ""

# Remove all existing Dock items
log_info "Removing all existing Dock items..."
if sudo -u "${username}" "${dockutilPath}" --no-restart --remove all "${userHomePath}" 2>/dev/null; then
  log_success "Cleared existing Dock items."
else
  log_warning "Could not clear Dock (it may already be empty)."
fi

echo ""

# Add applications to Dock
log_info "Adding applications to Dock..."
for app in "${DOCK_APPS[@]}"; do
  if [ -e "${app}" ]; then
    if sudo -u "${username}" "${dockutilPath}" --no-restart --add "${app}" "${userHomePath}" 2>/dev/null; then
      log_success "Added: ${app}"
    else
      log_warning "Failed to add: ${app}"
    fi
  else
    log_warning "Application not found (skipping): ${app}"
  fi
done

echo ""

# Restart Dock to apply changes
log_info "Restarting Dock to apply changes..."
if sudo -u "${username}" killall Dock 2>/dev/null; then
  log_success "Dock restarted successfully."
else
  log_warning "Could not restart Dock (it may not be running)."
fi

script_footer "success"
