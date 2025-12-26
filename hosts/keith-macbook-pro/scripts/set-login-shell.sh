#!/bin/bash

# ========================================================================
# Set Login Shell
# ========================================================================
# This script sets the login shell for a user to Nushell (nu).
# It ensures the shell is registered in /etc/shells before changing.
#
# Usage: set-login-shell.sh <username>
# Example: set-login-shell.sh keithhuster
# ========================================================================

set -e  # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers (skip if already sourced by parent)
if ! command -v script_header &> /dev/null; then
    source "${SCRIPT_DIR}/script-helpers.sh"
fi

# Display script header
script_header "Set Login Shell" "Configures Nushell as the user's login shell"

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
shellPath="/run/current-system/sw/bin/nu"

# Validate username exists
if ! id "${username}" &>/dev/null; then
    log_error "User '${username}' does not exist."
    exit 1
fi

# Validate shell path exists
if [ ! -f "${shellPath}" ]; then
    log_error "Shell not found at '${shellPath}'."
    log_info "Ensure Nushell is installed via nix-darwin."
    exit 1
fi

# Validate shell is executable
if [ ! -x "${shellPath}" ]; then
    log_error "Shell at '${shellPath}' is not executable."
    exit 1
fi

# ------------------------------------------------------------------------
# Ensure Shell is Registered in /etc/shells
# ------------------------------------------------------------------------

log_info "Configuring Nushell (nu) as the login shell for ${username}..."
echo ""

if ! grep -qxF "${shellPath}" /etc/shells; then
    log_info "Adding ${shellPath} to /etc/shells..."
    if echo "${shellPath}" | sudo tee -a /etc/shells >/dev/null; then
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
    if sudo -u "${username}" chsh -s "${shellPath}"; then
        log_success "Login shell changed successfully."
        log_info "Please log out and log back in for changes to take effect."
    else
        log_error "Failed to change login shell."
        exit 1
    fi
fi

script_footer "success"
