#!/usr/bin/env bash
set -euo pipefail

# Validate every host's configuration and manifests
#
# `dev:validate-host-config` resolves the host from `hostname -s`, which only
# works on a machine this repo actually manages. CI runners have an unrelated
# hostname, so this walks hosts/ instead and validates each one, reporting all
# failures rather than stopping at the first.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔍 Validating all host configurations..."
echo ""

mapfile -t host_dirs < <(find hosts -mindepth 1 -maxdepth 1 -type d | sort)

if [ "${#host_dirs[@]}" -eq 0 ]; then
  echo "⚠️  No hosts found under hosts/"
  exit 0
fi

gha_summary_heading "Host configuration"
gha_summary_table "" "Host" "Result"

failed=0
for host_dir in "${host_dirs[@]}"; do
  hostname="$(basename "$host_dir")"
  echo "── $hostname ──"
  gha_group "$hostname"
  if "$REPO_ROOT/tasks/scripts/tasks-dev-validate-host-config.sh" \
    "$REPO_ROOT/$host_dir" "$hostname"; then
    gha_summary_row "✅" "\`$hostname\`" "valid"
  else
    failed=$((failed + 1))
    gha_summary_row "❌" "\`$hostname\`" "**failed validation**"
    gha_error "Host $hostname failed configuration validation" "$host_dir/host-manifest.yml"
  fi
  gha_endgroup
  echo ""
done

if [ "$failed" -eq 0 ]; then
  echo "✅ All ${#host_dirs[@]} host(s) valid!"
  gha_summary_result ok "All ${#host_dirs[@]} host(s) valid"
else
  gha_summary_result fail "$failed of ${#host_dirs[@]} host(s) failed validation"
  echo "❌ $failed of ${#host_dirs[@]} host(s) failed validation"
  exit 1
fi
