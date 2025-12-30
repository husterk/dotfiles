#!/usr/bin/env bash
set -euo pipefail

# Capture dotfiles back to source with optional dry-run

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
DRY_RUN="${3:-}"

if [ "$DRY_RUN" = "--dry-run" ]; then
  echo "🔍 Previewing dotfile capture (dry-run mode)..."
  "$BOOTSTRAP_SCRIPTS_DIR/capture-dotfiles.sh" "$HOSTNAME" --dry-run
else
  echo "🔄 Capturing dotfiles back to source..."
  "$BOOTSTRAP_SCRIPTS_DIR/capture-dotfiles.sh" "$HOSTNAME"
  echo "✅ Dotfiles captured successfully!"
  echo ""
  echo "Review changes with: git diff"
fi
