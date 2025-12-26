#!/bin/bash

# ========================================================================
# SSH to Host Wrapper Script
# ========================================================================
# This script provides SSH access from the devcontainer to the host machine.
# It uses the HOST_USER environment variable to connect with the correct username.
#
# Used by the "zsh (host)" terminal profile in VS Code.
# ========================================================================

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
# Get the directory where this script is located (.devcontainer/scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers
source "${SCRIPT_DIR}/script-helpers.sh"

# Display script header
script_header "SSH to Host" "Connecting to host machine via SSH"

# ------------------------------------------------------------------------
# Validate Environment
# ------------------------------------------------------------------------

# Validate HOST_USER is set
if [ -z "$HOST_USER" ]; then
    log_error "HOST_USER environment variable not set."
    echo ""
    echo "This variable should be automatically set by the devcontainer."
    echo "Please rebuild the devcontainer or check devcontainer.json configuration."
    echo ""
    echo "Press Enter to close this terminal..."
    read -r
    exit 1
fi

# ------------------------------------------------------------------------
# Connect to Host
# ------------------------------------------------------------------------

# SSH to host with configured options
# Explicitly start zsh (regardless of login shell) and change to dotfiles directory
# Use bash to execute the command to avoid nushell parsing issues
# Try Nix-managed zsh first, fallback to system zsh if not available
log_info "Connecting to host as ${HOST_USER}..."

ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o LogLevel=ERROR \
    -t "$HOST_USER@host.docker.internal" \
    '/bin/bash -c '"'"'cd ~/git-repos/dotfiles 2>/dev/null || cd ~; if [ -x /run/current-system/sw/bin/zsh ]; then exec /run/current-system/sw/bin/zsh -l; elif [ -x /bin/zsh ]; then exec /bin/zsh -l; else echo "ERROR: zsh not found"; sleep 5; exit 1; fi'"'"''

# ------------------------------------------------------------------------
# Connection Closed
# ------------------------------------------------------------------------

# If SSH exits, show message before closing
log_info "SSH connection closed."
echo "Press Enter to close this terminal..."
read -r
script_footer "success"
