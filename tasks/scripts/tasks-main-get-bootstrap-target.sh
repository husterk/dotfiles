#!/usr/bin/env bash
set -euo pipefail

# Get bootstrap target from host manifest
# Usage: get-bootstrap-target.sh <host-manifest-path>

MANIFEST_PATH="${1:-}"

# Default to macos-arm64 if no manifest or target not found
DEFAULT_TARGET="macos-arm64"

# If no manifest path provided or file doesn't exist, return default
if [ -z "$MANIFEST_PATH" ] || [ ! -f "$MANIFEST_PATH" ]; then
  echo "$DEFAULT_TARGET"
  exit 0
fi

# Try to extract bootstrap-target using yq (preferred)
if command -v yq &> /dev/null; then
  target=$(yq eval '.config.bootstrap-target // ""' "$MANIFEST_PATH" 2> /dev/null || echo "")
  if [ -n "$target" ]; then
    echo "$target"
    exit 0
  fi
fi

# Fallback: use awk to extract from YAML
target=$(awk '
  /^config:/ { in_config=1; next }
  in_config && /^[^ ]/ { in_config=0 }
  in_config && /bootstrap-target:/ {
    gsub(/^[[:space:]]*bootstrap-target:[[:space:]]*/, "")
    gsub(/[[:space:]]*$/, "")
    print
    exit
  }
' "$MANIFEST_PATH" 2> /dev/null | tr -d '\r')

# Return extracted target or default
if [ -n "$target" ]; then
  echo "$target"
else
  echo "$DEFAULT_TARGET"
fi
