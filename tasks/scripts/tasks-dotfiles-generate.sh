#!/usr/bin/env bash
set -euo pipefail

# Generate dotfiles from templates

BOOTSTRAP_SCRIPTS_DIR="${1:?BOOTSTRAP_SCRIPTS_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"
HOST_DIR="${3:?HOST_DIR required}"

echo "📝 Generating dotfiles from templates..."
"$BOOTSTRAP_SCRIPTS_DIR/generate-dotfiles.sh" "$HOSTNAME"
echo "✅ Generated: $HOST_DIR/generated/dotfiles/"
