#!/usr/bin/env bash
set -euo pipefail

# Format shell scripts with shfmt

REPO_ROOT="${1:?REPO_ROOT required}"

cd "$REPO_ROOT"

echo "✨ Formatting shell scripts..."
echo ""

if ! command -v shfmt &>/dev/null; then
  echo "❌ shfmt not installed"
  exit 1
fi

find . -type f -name "*.sh" ! -path "./.nix-shell/*" ! -path "./hosts/*/generated/*" -exec shfmt -w -i 2 -ci {} \;

echo "✅ Format complete!"
