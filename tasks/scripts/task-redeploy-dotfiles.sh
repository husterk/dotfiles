#!/usr/bin/env bash
set -euo pipefail

# Redeploy dotfiles (unstow + stow)

HOST_DIR="${1:?HOST_DIR required}"

echo "🔄 Redeploying dotfiles..."
cd "$HOST_DIR/generated"
stow -D --target="$HOME" dotfiles 2>/dev/null || true
stow -v --target="$HOME" dotfiles
echo "✅ Dotfiles redeployed successfully!"
