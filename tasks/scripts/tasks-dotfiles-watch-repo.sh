#!/usr/bin/env bash
set -euo pipefail

# Watch templates for changes and auto-regenerate
# This script monitors app template directories for changes

REPO_ROOT="${1:?REPO_ROOT required}"

echo "👀 Watching templates for changes..."
echo "   Monitoring: apps/*/dotfiles/**"
echo "   Press Ctrl+C to stop"
echo ""

if command -v fswatch &>/dev/null; then
  fswatch -o "$REPO_ROOT/apps"/*/dotfiles/ | while read -r _; do
    echo "🔄 Template change detected, regenerating..."
    task bootstrap:generate-dotfiles
    echo ""
  done
else
  echo "⚠️  fswatch not installed (install fswatch for this feature)"
  exit 1
fi
