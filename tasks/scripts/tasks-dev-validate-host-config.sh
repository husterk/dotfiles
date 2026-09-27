#!/usr/bin/env bash
set -euo pipefail

# Validate host configuration and manifests
# Checks TOML syntax, required files, etc.

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

# Check the TOML files Nix and the dotfile scripts both read
for toml in host-manifest.toml host-vars.toml; do
  if [ -f "$HOST_DIR/$toml" ]; then
    if command -v yq &> /dev/null; then
      if yq -p toml -o yaml eval . "$HOST_DIR/$toml" &> /dev/null; then
        echo "✅ $toml syntax valid"
      else
        echo "❌ $toml syntax invalid"
        errors=$((errors + 1))
      fi
    else
      echo "⚠️  Cannot validate TOML (yq not installed)"
    fi
  else
    echo "❌ $toml not found"
    errors=$((errors + 1))
  fi
done

# Check configuration.nix
if [ -f "$HOST_DIR/configuration.nix" ]; then
  echo "✅ configuration.nix exists"
else
  echo "❌ configuration.nix not found"
  errors=$((errors + 1))
fi

echo ""

if [ "$errors" -eq 0 ]; then
  echo "✅ All validation checks passed!"
else
  echo "❌ Validation failed with $errors error(s)"
  exit 1
fi
