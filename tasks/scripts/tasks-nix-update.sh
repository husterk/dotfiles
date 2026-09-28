#!/usr/bin/env bash
set -euo pipefail

# Update Nix flake inputs and lock file

REPO_ROOT="${1:?REPO_ROOT required}"

echo "⚙️  Updating flake inputs..."

# Capture the output first: reading PIPESTATUS after a pipeline inside a ||
# block reports the test commands' status, not nix's, so failures used to
# exit 0.
if ! out="$(nix flake update --flake "$REPO_ROOT" 2>&1)"; then
  printf '%s\n' "$out"
  echo "❌ nix flake update failed"
  exit 1
fi
printf '%s\n' "$out" | grep -v "warning: Git tree.*is dirty" || true

echo "✅ Flake inputs updated. Run 'mise run nix:apply' to apply changes."
