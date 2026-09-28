#!/usr/bin/env bash
set -euo pipefail

# Show available tasks and current configuration

HOSTNAME="${1:?HOSTNAME required}"
BOOTSTRAP_TARGET="${2:?BOOTSTRAP_TARGET required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                        Dotfiles Repository                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Current Configuration:"
echo "  • Hostname:          $HOSTNAME"
echo "  • Bootstrap Target:  $BOOTSTRAP_TARGET"
echo "  • Host Directory:    $HOST_DIR"
echo ""
if [ -f "$HOST_DIR/host-manifest.toml" ]; then
  echo "✅ Host manifest found"
else
  echo "⚠️  Host manifest not found"
fi
echo ""
echo "📚 Available Commands:"
echo ""
mise tasks
echo ""
echo "💡 Override the host: DOTFILES_HOST=my-host mise run [command]"
echo "💡 Set up new host: mise run setup (for new hosts)"
echo "💡 Refresh existing host: mise run refresh (regenerate and redeploy)"
echo ""
