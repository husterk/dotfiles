#!/bin/sh
# Devcontainer initialization script - runs on the host before container creation
# This script sets up the .env file required by the devcontainer using 1Password CLI

set -eu

# Get the directory where this script is located (.devcontainer/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Add common paths where op might be installed
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Check if 1Password CLI is installed
if ! command -v op >/dev/null 2>&1; then
    echo "Error: 1Password CLI (op) is not installed."
    echo "Please install it from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Check if user is signed in to 1Password
if ! op whoami >/dev/null 2>&1; then
    echo "You are not signed in to 1Password."
    echo "Attempting to sign in..."
    echo ""
    
    # Attempt to sign in (this will prompt the user interactively)
    if ! op signin; then
        echo ""
        echo "Error: Failed to sign in to 1Password."
        echo "Please sign in manually with: op signin"
        exit 1
    fi
    
    echo ""
    echo "✓ Successfully signed in to 1Password!"
fi

# Set up the devcontainer '.env' file using the 1Password CLI
echo "Setting up devcontainer .env file..."
op inject -f -i "$SCRIPT_DIR/.env.template" -o "$SCRIPT_DIR/.env" --file-mode 0644

echo "✓ Devcontainer .env file created successfully!"
echo "Container build will now proceed..."
