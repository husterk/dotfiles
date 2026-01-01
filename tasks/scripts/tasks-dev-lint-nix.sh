#!/usr/bin/env bash
set -euo pipefail

# Lint Nix files with statix

REPO_ROOT="${1:?REPO_ROOT required}"

cd "$REPO_ROOT"

echo "🔍 Linting Nix files..."
echo ""

if ! command -v statix &> /dev/null; then
  echo "❌ statix not installed"
  exit 1
fi

# Find all Nix files to lint (exclude templates and generated files)
mapfile -t nix_files < <(find . -type f -name "*.nix" ! -name "*-template.nix" ! -path "./.nix-shell/*" ! -path "./hosts/*/generated/*" | sort)

if [ "${#nix_files[@]}" -eq 0 ]; then
  echo "⚠️  No Nix files found"
  exit 0
fi

echo "Found ${#nix_files[@]} Nix file(s) to lint:"
for file in "${nix_files[@]}"; do
  echo "  • $file"
done
echo ""

# Run statix check on each file individually
# This ensures we only check the files we've filtered
errors=0
for file in "${nix_files[@]}"; do
  if ! statix check "$file" 2>&1; then
    errors=$((errors + 1))
  fi
done

if [ "$errors" -eq 0 ]; then
  echo ""
  echo "✅ All ${#nix_files[@]} Nix file(s) passed!"
else
  echo ""
  echo "❌ Lint failed - please fix the issues above"
  exit 1
fi
