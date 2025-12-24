#!/bin/bash

# ========================================================================
# SSH to Host Wrapper Script
# ========================================================================
# This script provides SSH access from the devcontainer to the host machine.
# It uses the HOST_USER environment variable to connect with the correct username.
#
# Used by the "zsh (host)" terminal profile in VS Code.
# ========================================================================

set -e  # Exit on error

# Color output for better visibility
RED='\033[0;31m'
NC='\033[0m' # No Color

# Validate HOST_USER is set
if [ -z "$HOST_USER" ]; then
    echo -e "${RED}[ERROR]${NC} HOST_USER environment variable not set."
    echo ""
    echo "This variable should be automatically set by the devcontainer."
    echo "Please rebuild the devcontainer or check devcontainer.json configuration."
    exit 1
fi

# SSH to host with configured options
# Start in the dotfiles repository directory
exec ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -t "$HOST_USER@host.docker.internal" \
    "cd ~/git-repos/dotfiles 2>/dev/null || cd ~; exec zsh -l"
