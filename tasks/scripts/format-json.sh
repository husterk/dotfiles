#!/usr/bin/env bash
# Format JSON files with jq

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"

echo "🎨 Formatting JSON files..."

# Find all JSON files, excluding generated directories, lock files, and VSCode config (JSONC)
find "$REPO_ROOT" -type f -name "*.json" \
  ! -name "flake.lock" \
  ! -name "package-lock.json" \
  ! -path "*/.vscode/*" \
  ! -path "*/generated/*" \
  ! -path "*/.task/*" \
  ! -path "*/.direnv/*" \
  ! -path "*/result/*" \
  ! -path "*/.git/*" \
  ! -path "*/node_modules/*" \
  -print0 | while IFS= read -r -d '' file; do
  echo "  Formatting: $file"
  # Format JSON with 2-space indentation
  # Suppress errors for files that might have comments
  if jq --indent 2 '.' "$file" >"${file}.tmp" 2>/dev/null; then
    mv "${file}.tmp" "$file"
  else
    echo "    ⚠️  Skipped (possibly JSONC with comments)"
    rm -f "${file}.tmp"
  fi
done

echo "✅ JSON formatting complete"
