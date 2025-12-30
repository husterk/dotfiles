#!/usr/bin/env bash
set -euo pipefail

# Development shell initialization hook
# This script runs when entering the Nix development shell

echo "🚀 Dotfiles development environment loaded"
echo ""
echo "Available tools:"
echo "  • task (v$(task --version)): Task runner"
echo "  • op (v$(op --version 2>/dev/null || echo 'not authenticated')): 1Password CLI"
echo "  • nvim (v$(nvim --version | head -n1 | awk '{print $2}')): Neovim"
echo ""

# Ensure 1Password CLI is authenticated
if ! op account list &> /dev/null; then
  echo "⚠️  Warning: 1Password CLI not authenticated"
  echo "   Run: eval \$(op signin)"
  echo ""
else
  # Auto-generate .env from template if it doesn't exist or template is newer
  if [ -f .nix-shell/.env.template ]; then
    if [ ! -f .env ] || [ .nix-shell/.env.template -nt .env ]; then
      echo "📝 Generating .env from 1Password..."
      if op inject -i .nix-shell/.env.template -o .env &>/dev/null; then
        echo "✅ Generated .env file"
      else
        echo "⚠️  Failed to generate .env (check 1Password vault access)"
      fi
      echo ""
    fi
  fi
fi

# Set up environment
export DOTFILES_ROOT="$PWD"
export PATH="$DOTFILES_ROOT:$PATH"

# Load .env file if it exists
if [ -f .env ]; then
  echo "📄 Loading environment from .env"
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

echo "Getting started:"
echo "  task                 # Show current status and available tasks"
echo "  task --list          # List all available tasks"
echo "  task dev:lint        # Lint all code (shell scripts + Nix)"
echo "  task dev:format      # Format all code (shell scripts + Nix)"
echo "  nvim                 # Open Neovim (with LSPs for bash, nix, lua, markdown)"
echo ""
