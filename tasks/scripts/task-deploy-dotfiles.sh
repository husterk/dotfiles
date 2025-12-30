#!/usr/bin/env bash
set -euo pipefail

# Deploy dotfiles using GNU Stow

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"

echo "📦 Deploying dotfiles using GNU Stow..."
"$BOOTSTRAP_SCRIPTS_DIR/deploy-dotfiles.sh" "$HOSTNAME"
echo "✅ Dotfiles deployed successfully!"
echo ""
echo "Symlinks created in your home directory."
