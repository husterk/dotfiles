#!/usr/bin/env bash
set -euo pipefail

# Generate .env file from 1Password secrets

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "🔐 Generating .env from 1Password secrets..."
"$BOOTSTRAP_SCRIPTS_DIR/generate-env.sh" "$HOSTNAME"
echo "✅ Generated: $HOST_DIR/generated/.env"
