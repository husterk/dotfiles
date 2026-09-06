#!/usr/bin/env bash
set -euo pipefail

# Lint all shell scripts in the repository with shellcheck

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔍 Linting shell scripts..."
echo ""

if ! command -v shellcheck &> /dev/null; then
  echo "❌ shellcheck not installed"
  exit 1
fi

# Find all shell scripts to lint
mapfile -t scripts < <(find . -type f -name "*.sh" ! -path "./hosts/*/generated/*" | sort)

if [ "${#scripts[@]}" -eq 0 ]; then
  echo "⚠️  No shell scripts found"
  exit 0
fi

echo "Found ${#scripts[@]} script(s) to lint:"
gha_group "${#scripts[@]} script(s) to lint"
for script in "${scripts[@]}"; do
  echo "  • $script"
done
gha_endgroup
echo ""

# Run shellcheck on all scripts
errors=0
failed_scripts=()
for script in "${scripts[@]}"; do
  if ! shellcheck -x "$script"; then
    echo ""
    echo "❌ Lint failed for: $script"
    failed_scripts+=("$script")
    gha_error "shellcheck found issues in $script" "${script#./}"
    errors=$((errors + 1))
  fi
done

gha_summary_heading "Shell lint (shellcheck)"
if [ "$errors" -eq 0 ]; then
  gha_summary_result ok "All ${#scripts[@]} script(s) passed shellcheck"
else
  gha_summary_table "" "Script"
  for script in "${failed_scripts[@]}"; do
    gha_summary_row "❌" "\`${script#./}\`"
  done
  gha_summary_result fail "$errors of ${#scripts[@]} script(s) failed shellcheck"
fi

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "❌ $errors script(s) failed linting"
  exit 1
fi

echo "✅ All ${#scripts[@]} script(s) passed!"
