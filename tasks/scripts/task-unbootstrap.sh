#!/usr/bin/env bash
set -euo pipefail

# Unbootstrap - remove Nix and nix-darwin from system

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"

echo "🗑️  Unbootstrapping host: $HOSTNAME..."
"$BOOTSTRAP_SCRIPTS_DIR/unbootstrap.sh" "$HOSTNAME"
echo "✅ Unbootstrap complete"
