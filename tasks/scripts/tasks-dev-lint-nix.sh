#!/usr/bin/env bash
set -euo pipefail

# Lint Nix files with statix

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔍 Linting Nix files..."
echo ""

if ! command -v statix &> /dev/null; then
  echo "❌ statix not installed"
  exit 1
fi

# Find all Nix files to lint (exclude templates and generated files)
mapfile -t nix_files < <(find . -type f -name "*.nix" ! -path "./.nix-shell/*" ! -path "./hosts/*/generated/*" | sort)

if [ "${#nix_files[@]}" -eq 0 ]; then
  echo "⚠️  No Nix files found"
  exit 0
fi

echo "Found ${#nix_files[@]} Nix file(s) to lint:"
gha_group "${#nix_files[@]} Nix file(s) to lint"
for file in "${nix_files[@]}"; do
  echo "  • $file"
done
gha_endgroup
echo ""

# Run statix check on each file individually
# This ensures we only check the files we've filtered
errors=0
failed_files=()
for file in "${nix_files[@]}"; do
  if ! statix check "$file" 2>&1; then
    failed_files+=("$file")
    gha_error "statix found issues in $file" "${file#./}"
    errors=$((errors + 1))
  fi
done

gha_summary_heading "Nix lint (statix)"
if [ "$errors" -eq 0 ]; then
  gha_summary_result ok "All ${#nix_files[@]} Nix file(s) passed statix"
else
  gha_summary_table "" "File"
  for file in "${failed_files[@]}"; do
    gha_summary_row "❌" "\`${file#./}\`"
  done
  gha_summary_result fail "$errors of ${#nix_files[@]} Nix file(s) failed statix"
fi

if [ "$errors" -eq 0 ]; then
  echo ""
  echo "✅ All ${#nix_files[@]} Nix file(s) passed!"
else
  echo ""
  echo "❌ Lint failed - please fix the issues above"
  exit 1
fi
