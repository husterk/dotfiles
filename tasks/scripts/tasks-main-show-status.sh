#!/usr/bin/env bash
set -euo pipefail

# Show current configuration status

HOSTNAME="${1:?HOSTNAME required}"
BOOTSTRAP_TARGET="${2:?BOOTSTRAP_TARGET required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                      Configuration Status                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Host Information:"
echo "  • Hostname:          $HOSTNAME"
echo "  • Bootstrap Target:  $BOOTSTRAP_TARGET"
echo "  • Host Directory:    $HOST_DIR"
echo ""
echo "📁 Files:"
if [ -f "$HOST_DIR/host-manifest.yml" ]; then
  echo "  ✅ host-manifest.yml"
else
  echo "  ❌ host-manifest.yml (missing)"
fi
if [ -f "$HOST_DIR/generated/.env" ]; then
  echo "  ✅ .env (generated)"
else
  echo "  ⚠️  .env (not generated)"
fi
if [ -f "$HOST_DIR/generated/configuration.nix" ]; then
  echo "  ✅ configuration.nix (generated)"
else
  echo "  ⚠️  configuration.nix (not generated)"
fi
if [ -d "$HOST_DIR/generated/dotfiles" ]; then
  echo "  ✅ dotfiles/ (generated)"
else
  echo "  ⚠️  dotfiles/ (not generated)"
fi
echo ""
echo "🔐 1Password:"
if op account list &> /dev/null; then
  echo "  ✅ Authenticated"
  op account list | tail -n +2 | while read -r line; do
    echo "     $(echo "$line" | awk '{print $2}') ($(echo "$line" | awk '{print $1}'))"
  done
else
  echo "  ❌ Not authenticated"
  echo "     Run: eval \$(op signin)"
fi
echo ""
echo "⚙️  Nix:"
if command -v nix &> /dev/null; then
  echo "  ✅ Nix installed ($(nix --version | awk '{print $3}'))"
else
  echo "  ❌ Nix not installed"
fi
if command -v darwin-rebuild &> /dev/null; then
  echo "  ✅ nix-darwin installed"
else
  echo "  ⚠️  nix-darwin not installed"
fi
echo ""
