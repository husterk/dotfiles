#!/usr/bin/env bash
set -euo pipefail

# Validate host configuration and manifests
# Checks YAML syntax, required files, etc.

HOST_DIR="${1:?HOST_DIR required}"
HOSTNAME="${2:?HOSTNAME required}"

echo "🔍 Validating configuration for $HOSTNAME..."
echo ""

errors=0

# Check host directory
if [ ! -d "$HOST_DIR" ]; then
  echo "❌ Host directory not found: $HOST_DIR"
  errors=$((errors + 1))
fi

# Check host-manifest.yml
if [ -f "$HOST_DIR/host-manifest.yml" ]; then
  if command -v yq &> /dev/null; then
    if yq eval . "$HOST_DIR/host-manifest.yml" &> /dev/null; then
      echo "✅ host-manifest.yml syntax valid"
    else
      echo "❌ host-manifest.yml syntax invalid"
      errors=$((errors + 1))
    fi
  else
    echo "⚠️  Cannot validate YAML (yq not installed)"
  fi
else
  echo "❌ host-manifest.yml not found"
  errors=$((errors + 1))
fi

# Check template.env
if [ -f "$HOST_DIR/template.env" ]; then
  echo "✅ template.env exists"
else
  echo "❌ template.env not found"
  errors=$((errors + 1))
fi

# Check configuration-template.nix
if [ -f "$HOST_DIR/configuration-template.nix" ]; then
  echo "✅ configuration-template.nix exists"
else
  echo "❌ configuration-template.nix not found"
  errors=$((errors + 1))
fi

# Check flake.nix
if [ -f "$HOST_DIR/flake.nix" ]; then
  echo "✅ flake.nix exists"
else
  echo "❌ flake.nix not found"
  errors=$((errors + 1))
fi

echo ""

if [ "$errors" -eq 0 ]; then
  echo "✅ All validation checks passed!"
else
  echo "❌ Validation failed with $errors error(s)"
  exit 1
fi
