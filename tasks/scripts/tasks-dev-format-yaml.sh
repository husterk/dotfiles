#!/usr/bin/env bash
# Format YAML files with yq

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"

echo "🎨 Formatting YAML files..."

# Find all YAML files, excluding generated directories
find "$REPO_ROOT" -type f \( -name "*.yml" -o -name "*.yaml" \) \
  ! -path "*/generated/*" \
  ! -path "*/.task/*" \
  ! -path "*/.direnv/*" \
  ! -path "*/result/*" \
  ! -path "*/.git/*" \
  -print0 | while IFS= read -r -d '' file; do
  echo "  Formatting: $file"
  # Format YAML in place with yq (2-space indent)
  # Using eval-all to preserve multi-document YAML files
  yq eval-all --inplace --indent 2 --prettyPrint '.' "$file"
done

echo "✅ YAML formatting complete"
