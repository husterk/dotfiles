#!/usr/bin/env bash
set -euo pipefail

# Generate .env file from host-vars.toml

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "⚙️  Generating .env from host-vars.toml..."
"$BOOTSTRAP_SCRIPTS_DIR/generate-env.sh" "$HOSTNAME"
echo "✅ Generated: $HOST_DIR/generated/.env"
