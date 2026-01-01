#!/usr/bin/env bash
set -euo pipefail

# Restore dotfiles from backup

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"

echo "♻️  Restoring dotfiles from backup..."
"$BOOTSTRAP_SCRIPTS_DIR/deploy-dotfiles.sh" "$HOSTNAME" --restore
echo "✅ Dotfiles restored from backup"
