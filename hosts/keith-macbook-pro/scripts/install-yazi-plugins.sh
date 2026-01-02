#!/usr/bin/env bash

# ========================================================================
# Install Yazi Plugins Script
# ========================================================================
# This script installs Yazi plugins by running Yazi's built-in plugin manager.
#
# Usage: install-yazi-plugins.sh [username] [ya-path]
# Example: install-yazi-plugins.sh keithhuster /nix/store/.../bin/ya
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers (skip if already sourced by parent)
if ! command -v script_header &> /dev/null; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/script-helpers.sh"
fi

# Display script header
script_header "Install Yazi Plugins" "Runs Yazi's built-in plugin manager to install plugins"

# ------------------------------------------------------------------------
# Validate Input Parameters
# ------------------------------------------------------------------------

if [ $# -ne 2 ]; then
  log_error "Invalid number of arguments."
  echo ""
  echo "Usage: $0 <username> <ya-path>"
  echo "Example: $0 keithhuster /nix/store/.../bin/ya"
  exit 1
fi

username="${1}"
yaPath="${2}"

# Validate username exists
if ! id "${username}" &> /dev/null; then
  log_error "User '${username}' does not exist."
  exit 1
fi

# Validate ya exists
if [ ! -f "${yaPath}" ]; then
  log_error "ya not found at '${yaPath}'."
  log_info "Ensure ya is installed and the path is correct."
  exit 1
fi

# Get user's home directory
user_home=$(eval echo "~${username}")

log_info "Installing Yazi plugins for user: ${username}"
log_info "Home directory: ${user_home}"
log_info "Using ya path: ${yaPath}"
echo ""

# ------------------------------------------------------------------------
# Clean Up Old Plugins
# ------------------------------------------------------------------------

# Remove old plugins to prevent accumulation of dead/unused plugins
plugins_dir="${user_home}/.config/yazi/plugins"
packages_dir="${user_home}/.local/state/yazi/packages"

if [ -d "${plugins_dir}" ]; then
  log_info "Cleaning up old plugins directory: ${plugins_dir}"
  rm -rf "${plugins_dir}"
fi

if [ -d "${packages_dir}" ]; then
  log_info "Cleaning up old packages directory: ${packages_dir}"
  rm -rf "${packages_dir}"
fi

# ------------------------------------------------------------------------
# Install Yazi Plugins using Yazi's Plugin Manager
# ------------------------------------------------------------------------

# Run as the user (not root) to access user's config
# ya pkg install reads from ~/.config/yazi/package.toml and installs all plugins
# Set HOME explicitly to ensure ya finds the correct config
log_info "Running: HOME=${user_home} ya pkg install"

if sudo -u "${username}" HOME="${user_home}" "${yaPath}" pkg install; then
  log_success "Yazi plugins installed successfully"
else
  log_warning "Yazi plugin installation completed with warnings (this may be normal if no plugins are configured)"
  log_info "Check ${user_home}/.config/yazi/package.toml for plugin configuration"
fi

script_footer "success"
