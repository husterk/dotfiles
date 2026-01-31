#!/usr/bin/env bash
set -euo pipefail

# Update Nix flake inputs and lock file

HOST_DIR="${1:?HOST_DIR required}"

echo "⚙️  Updating flake inputs..."
cd "$HOST_DIR"

# Update flake.lock (suppress Git dirty tree warnings)
nix flake update 2>&1 | grep -v "warning: Git tree.*is dirty" || {
  # If the command fails, show the error but check if lock file was updated
  if [ "${PIPESTATUS[0]}" -ne 0 ] && [ "${PIPESTATUS[0]}" -ne 141 ]; then
    exit "${PIPESTATUS[0]}"
  fi
}

echo "✅ Flake inputs updated. Run 'mise run nix:apply' to apply changes."
