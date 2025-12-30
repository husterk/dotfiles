#!/usr/bin/env bash
set -euo pipefail

# Generate Nix configuration from template

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "⚙️  Generating Nix configuration..."
"$BOOTSTRAP_SCRIPTS_DIR/generate-nix-config.sh" "$HOSTNAME"
echo "✅ Generated: $HOST_DIR/generated/configuration.nix"
