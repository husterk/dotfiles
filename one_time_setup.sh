#!/usr/bin/env zsh
# The one-time-setup script required to initialize the local repository.

set -euo pipefail

# Change to the repository root directory
cd "$(dirname "$0")"

# Check if 1Password CLI is installed
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) is not installed."
    echo "Please install it from: https://developer.1password.com/docs/cli/get-started/"
    exit 1
fi

# Check if user is signed in to 1Password
if ! op whoami &> /dev/null; then
    echo "Error: You are not signed in to 1Password."
    echo "Please run: op signin"
    exit 1
fi

# Set up the devcontainer '.env' file using the 1Password CLI
echo "Setting up devcontainer .env file..."
op inject -f -i ./.devcontainer/.env.template -o ./.devcontainer/.env --file-mode 0644

echo "✓ Devcontainer .env file created successfully!"
echo "You can now open the project in VS Code and reopen in the devcontainer."
