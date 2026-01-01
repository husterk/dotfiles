#!/usr/bin/env bash
set -euo pipefail

# List all available hosts in the repository

REPO_ROOT="${1:?REPO_ROOT required}"
CURRENT_HOSTNAME="${2:?CURRENT_HOSTNAME required}"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                      Available Hosts                             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

for host_dir in "$REPO_ROOT"/hosts/*; do
  if [ -d "$host_dir" ] && [ -f "$host_dir/host-manifest.yml" ]; then
    hostname=$(basename "$host_dir")

    # Get bootstrap target
    if command -v yq &> /dev/null; then
      target=$(yq eval '.config.bootstrap-target // "macos-arm64"' "$host_dir/host-manifest.yml" 2> /dev/null)
    else
      target="macos-arm64"
    fi

    # Check if current host
    current=""
    if [ "$hostname" = "$CURRENT_HOSTNAME" ]; then
      current=" (current)"
    fi

    echo "📍 $hostname$current"
    echo "   Target: $target"

    # Check what's generated
    if [ -f "$host_dir/generated/.env" ]; then
      echo "   ✅ .env generated"
    else
      echo "   ⚠️  .env not generated"
    fi

    if [ -f "$host_dir/generated/configuration.nix" ]; then
      echo "   ✅ configuration.nix generated"
    else
      echo "   ⚠️  configuration.nix not generated"
    fi

    if [ -d "$host_dir/generated/dotfiles" ]; then
      echo "   ✅ dotfiles generated"
    else
      echo "   ⚠️  dotfiles not generated"
    fi

    echo ""
  fi
done
