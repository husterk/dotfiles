#!/usr/bin/env bash
set -euo pipefail

# Watch dotfiles (on the host) for changes and auto-capture
# This script monitors ~/.config for changes and triggers capture when detected

echo "👀 Watching dotfiles for changes..."
echo "   Monitoring: ~/.config/*"
echo "   Press Ctrl+C to stop"
echo ""

# Use fswatch if available, otherwise fall back to a simple loop
if command -v fswatch &> /dev/null; then
  fswatch -o "$HOME/.config" | while read -r _; do
    echo "🔄 Change detected, capturing..."
    mise run dotfiles:capture
    echo ""
  done
else
  echo "⚠️  fswatch not installed, using basic polling (install fswatch for better performance)"
  echo ""
  while true; do
    sleep 5
    if find "$HOME/.config" -newer /tmp/dotfiles-watch-marker 2> /dev/null | grep -q .; then
      echo "🔄 Change detected, capturing..."
      mise run dotfiles:capture
      echo ""
    fi
    touch /tmp/dotfiles-watch-marker
    sleep 5
  done
fi
