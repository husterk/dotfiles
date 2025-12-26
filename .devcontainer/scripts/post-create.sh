#!/bin/bash

# ========================================================================
# Devcontainer Post-Create Script
# ========================================================================
# This script runs after the devcontainer is created and performs:
# - SSH configuration (symlink host SSH keys)
# - VS Code shell integration setup for zsh
# - Node.js package installation
#
# This script is executed via the postCreateCommand in devcontainer.json
# ========================================================================

set -e  # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
# Get the directory where this script is located (.devcontainer/scripts/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers
source "${SCRIPT_DIR}/script-helpers.sh"

# Display script header
script_header "Devcontainer Post-Create" "Configures SSH, shell integration, and installs packages"

# ------------------------------------------------------------------------
# Step 1: Configure SSH Keys
# ------------------------------------------------------------------------
log_info "Configuring SSH access to host..."

if [ -d /home/vscode/.ssh-host ]; then
    log_info "Symlinking host SSH keys..."
    ln -sf /home/vscode/.ssh-host /home/vscode/.ssh
    log_success "SSH keys configured from host."
else
    log_warning "Host SSH directory not found (this is expected if not mounting SSH keys)."
fi

# ------------------------------------------------------------------------
# Step 2: Configure VS Code Shell Integration
# ------------------------------------------------------------------------
log_info "Configuring VS Code shell integration for zsh..."

# shellcheck disable=SC2016  # We want literal $ in the string (not expanded)
SHELL_INTEGRATION_LINE='[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"'

if ! grep -q "shell-integration-path zsh" ~/.zshrc 2>/dev/null; then
    echo "$SHELL_INTEGRATION_LINE" >> ~/.zshrc
    log_success "Shell integration added to ~/.zshrc"
else
    log_success "Shell integration already configured."
fi

# ------------------------------------------------------------------------
# Step 3: Install Node.js Packages
# ------------------------------------------------------------------------
log_info "Installing Node.js packages..."

if [ -f /workspace/package.json ]; then
    cd /workspace
    if bun install --frozen-lockfile; then
        log_success "Node.js packages installed successfully."
    else
        log_error "Failed to install Node.js packages."
        exit 1
    fi
else
    log_warning "No package.json found, skipping package installation."
fi

# ------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------
log_info "Devcontainer is ready to use."
script_footer "success"
