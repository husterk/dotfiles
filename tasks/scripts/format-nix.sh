#!/usr/bin/env bash
set -euo pipefail

# Format Nix files with nixpkgs-fmt

REPO_ROOT="${1:?REPO_ROOT required}"

cd "$REPO_ROOT"

echo "✨ Formatting Nix files..."
echo ""

if ! command -v nixpkgs-fmt &>/dev/null; then
  echo "❌ nixpkgs-fmt not installed"
  exit 1
fi

# Find all Nix files to format
mapfile -t nix_files < <(find . -type f -name "*.nix" ! -path "./.nix-shell/*" ! -path "./hosts/*/generated/*" | sort)

if [ "${#nix_files[@]}" -eq 0 ]; then
  echo "⚠️  No Nix files found"
  exit 0
fi

echo "Found ${#nix_files[@]} Nix file(s) to format:"
for file in "${nix_files[@]}"; do
  echo "  • $file"
done
echo ""

# Format all Nix files
for file in "${nix_files[@]}"; do
  nixpkgs-fmt "$file"
done

echo "✅ All ${#nix_files[@]} Nix file(s) formatted!"
