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
reformatted_count=0
for file in "${nix_files[@]}"; do
  # Capture nixpkgs-fmt output and only show if file was reformatted
  output=$(nixpkgs-fmt "$file" 2>&1)
  if echo "$output" | grep -q "1 / 1 have been reformatted"; then
    echo "  ✓ Reformatted: $file"
    ((reformatted_count++))
  fi
done

if [ "$reformatted_count" -gt 0 ]; then
  echo ""
  echo "✅ Reformatted $reformatted_count of ${#nix_files[@]} Nix file(s)"
else
  echo "✅ All ${#nix_files[@]} Nix file(s) already formatted"
fi
