#!/usr/bin/env bash
set -euo pipefail

# Validate every host's configuration and manifests
#
# `dev:validate-host-config` resolves the host from `hostname -s`, which only
# works on a machine this repo actually manages. CI runners have an unrelated
# hostname, so this walks hosts/ instead and validates each one, reporting all
# failures rather than stopping at the first.

REPO_ROOT="${1:?REPO_ROOT required}"

cd "$REPO_ROOT"

echo "🔍 Validating all host configurations..."
echo ""

mapfile -t host_dirs < <(find hosts -mindepth 1 -maxdepth 1 -type d | sort)

if [ "${#host_dirs[@]}" -eq 0 ]; then
  echo "⚠️  No hosts found under hosts/"
  exit 0
fi

failed=0
for host_dir in "${host_dirs[@]}"; do
  hostname="$(basename "$host_dir")"
  echo "── $hostname ──"
  if ! "$REPO_ROOT/tasks/scripts/tasks-dev-validate-host-config.sh" \
    "$REPO_ROOT/$host_dir" "$hostname"; then
    failed=$((failed + 1))
  fi
  echo ""
done

if [ "$failed" -eq 0 ]; then
  echo "✅ All ${#host_dirs[@]} host(s) valid!"
else
  echo "❌ $failed of ${#host_dirs[@]} host(s) failed validation"
  exit 1
fi
