#!/usr/bin/env bash
set -euo pipefail

# Clean generated files for the current host
# Removes .env, configuration.nix, and dotfiles/ (backups preserved)

HOST_DIR="${1:?HOST_DIR required}"

echo "🗑️  Cleaning generated files..."

if [ -f "$HOST_DIR/generated/.env" ]; then
  rm "$HOST_DIR/generated/.env"
  echo "  ✓ Removed .env"
fi

if [ -f "$HOST_DIR/generated/configuration.nix" ]; then
  rm "$HOST_DIR/generated/configuration.nix"
  echo "  ✓ Removed configuration.nix"
fi

if [ -d "$HOST_DIR/generated/dotfiles" ]; then
  rm -rf "$HOST_DIR/generated/dotfiles"
  echo "  ✓ Removed dotfiles/"
fi

echo "✅ Clean complete!"
echo ""
echo "To regenerate: mise run generate-all"
