#!/usr/bin/env bash
set -euo pipefail

# Show available tasks and current configuration

HOSTNAME="${1:?HOSTNAME required}"
BOOTSTRAP_TARGET="${2:?BOOTSTRAP_TARGET required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║               Dotfiles Task Runner (2025 Edition)                ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Current Configuration:"
echo "  • Hostname:          $HOSTNAME"
echo "  • Bootstrap Target:  $BOOTSTRAP_TARGET"
echo "  • Host Directory:    $HOST_DIR"
echo ""
if [ -f "$HOST_DIR/host-manifest.yml" ]; then
  echo "✅ Host manifest found"
else
  echo "⚠️  Host manifest not found"
fi
echo ""
echo "📚 Available Commands:"
echo ""
task --list
echo ""
echo "💡 Override hostname: task HOSTNAME=my-host [command]"
echo "💡 Set up new host: task setup-host (for new hosts)"
echo "💡 Refresh existing host: task refresh-host (regenerate and redeploy)"
echo ""
