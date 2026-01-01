#!/usr/bin/env bash
set -euo pipefail

# Lint all shell scripts in the repository with shellcheck

REPO_ROOT="${1:?REPO_ROOT required}"

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
for script in "${scripts[@]}"; do
  echo "  • $script"
done
echo ""

# Run shellcheck on all scripts
errors=0
for script in "${scripts[@]}"; do
  if ! shellcheck -x "$script"; then
    echo ""
    echo "❌ Lint failed for: $script"
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "❌ $errors script(s) failed linting"
  exit 1
fi

echo "✅ All ${#scripts[@]} script(s) passed!"
