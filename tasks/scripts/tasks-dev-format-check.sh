#!/usr/bin/env bash
set -euo pipefail

# Fail if the tree is not already formatted
#
# Wraps `treefmt --ci` (which implies --no-cache and --fail-on-change) and
# turns the result into a GitHub Actions summary naming the files that were
# not clean - the log alone only reports a count.
#
# Note treefmt still writes: the formatters run in place and the run then
# fails if anything changed. That is fine on an ephemeral runner, and locally
# it means `git diff` afterwards shows exactly what it fixed.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "✨ Checking formatting with treefmt..."
echo ""

if ! command -v treefmt &> /dev/null; then
  echo "❌ treefmt not installed"
  exit 1
fi

# Snapshot content hashes first: treefmt rewrites in place, so comparing
# hashes before and after isolates exactly what *it* changed.
#
# Neither `git diff` alone nor a before/after dirty-file comparison is right
# here. The former also blames edits already in the working tree; the latter
# misses a file that was dirty to begin with, because it appears on both
# sides. Hashing is accurate whatever state the tree starts in, which matters
# because this is meant to be run locally as well as on a pristine runner.
hash_manifest() {
  git ls-files --cached --others --exclude-standard |
    sort |
    while IFS= read -r f; do
      [ -f "$f" ] && printf '%s  %s\n' "$(shasum -a 256 "$f" | cut -d" " -f1)" "$f"
    done
}

before="$(hash_manifest)"

gha_group "treefmt output"
set +e
treefmt --ci
treefmt_status=$?
set -e
gha_endgroup

after="$(hash_manifest)"

gha_summary_heading "Formatting (treefmt)"

if [ "$treefmt_status" -eq 0 ]; then
  echo ""
  echo "✅ Formatting is clean"
  gha_summary_result ok "Formatting is clean"
  exit 0
fi

# Any manifest line present after but not before means that file's content
# changed; take the path column.
mapfile -t changed < <(
  comm -13 <(printf '%s\n' "$before" | sort) <(printf '%s\n' "$after" | sort) |
    sed 's/^[0-9a-f]*  //'
)

echo ""
echo "❌ Formatting is not clean"

if [ "${#changed[@]}" -gt 0 ]; then
  echo ""
  echo "Files needing formatting:"
  gha_summary_table "" "File"
  for file in "${changed[@]}"; do
    echo "  • $file"
    gha_summary_row "❌" "\`$file\`"
    gha_error "Not formatted - run 'mise run dev:format'" "$file"
  done
  gha_summary_result fail "${#changed[@]} file(s) need formatting"
else
  gha_summary_result fail "treefmt reported changes (exit $treefmt_status)"
fi

echo ""
echo "Run 'mise run dev:format' to fix."
exit 1
