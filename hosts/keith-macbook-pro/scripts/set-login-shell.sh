#!/usr/bin/env bash

# ========================================================================
# Set Login Shell
# ========================================================================
# This script sets the login shell for a user to zsh. The login shell must
# be POSIX compatible so nix can set environment variables through it.
# Nushell or another preferred shell can still run as the interactive shell,
# launched by a terminal emulator such as WezTerm.
#
# It ensures the shell is registered in /etc/shells before changing.
#
# Usage: set-login-shell.sh <username>
# Example: set-login-shell.sh keithhuster
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers (skip if already sourced by parent)
if ! command -v script_header &> /dev/null; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/../../../scripts/script-helpers.sh"
fi

# Display script header
script_header "Set Login Shell" "Configures zsh as the user's login shell"

# ------------------------------------------------------------------------
# Validate Input Parameters
# ------------------------------------------------------------------------

if [ $# -ne 1 ]; then
  log_error "Invalid number of arguments."
  echo ""
  echo "Usage: $0 <username>"
  echo "Example: $0 keithhuster"
  exit 1
fi

username="${1}"
shellPath="/run/current-system/sw/bin/zsh"

# Validate username exists
if ! id "${username}" &> /dev/null; then
  log_error "User '${username}' does not exist."
  exit 1
fi

# Validate shell path exists
# On the first switch /run/current-system only points at the new system
# once activation finishes, so the shell is not there yet. Skip, and let the
# next apply set it.
if [ ! -e "${shellPath}" ]; then
  log_warning "Shell not there yet at '${shellPath}'; skipping until the next apply."
  script_footer "warning" "login shell not changed yet"
  exit 0
fi

# Validate shell is executable
if [ ! -x "${shellPath}" ]; then
  log_error "Shell at '${shellPath}' is not executable."
  exit 1
fi

# ------------------------------------------------------------------------
# Ensure Shell is Registered in /etc/shells
# ------------------------------------------------------------------------

log_info "Configuring zsh as the login shell for ${username}..."
echo ""

if ! grep -qxF "${shellPath}" /etc/shells; then
  log_info "Adding ${shellPath} to /etc/shells..."
  if echo "${shellPath}" | sudo tee -a /etc/shells > /dev/null; then
    log_success "Shell registered in /etc/shells."
  else
    log_error "Failed to add shell to /etc/shells."
    exit 1
  fi
else
  log_success "Shell already registered in /etc/shells."
fi

echo ""

# ------------------------------------------------------------------------
# Change Login Shell
# ------------------------------------------------------------------------

log_info "Changing login shell for ${username} to ${shellPath}..."

# Get current shell
currentShell=$(dscl . -read "/Users/${username}" UserShell | awk '{print $2}')

if [ "${currentShell}" = "${shellPath}" ]; then
  log_success "Login shell is already set to ${shellPath}."
else
  log_info "Current shell: ${currentShell}"
  # Activation runs as root. chsh as the user would prompt for their
  # password, which fails when darwin-rebuild has no terminal.
  if sudo dscl . -create "/Users/${username}" UserShell "${shellPath}"; then
    log_success "Login shell changed successfully."
    log_info "Please log out and log back in for changes to take effect."
  else
    log_error "Failed to change login shell."
    exit 1
  fi
fi

script_footer "success"
