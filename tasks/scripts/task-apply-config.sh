#!/usr/bin/env bash
set -euo pipefail

# Apply Nix configuration to system

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"

echo "⚙️  Applying Nix configuration..."
"$BOOTSTRAP_SCRIPTS_DIR/apply-config.sh" "$HOSTNAME"
echo "✅ Configuration applied successfully!"
