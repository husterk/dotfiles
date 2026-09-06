#!/usr/bin/env bash
set -euo pipefail

# Fail on British spellings in tracked Markdown
#
# Enforces the "Always US English" rule in the deployed
# apps/claude/dotfiles/rules/communication.md. The scanner blanks fenced blocks
# and inline code first, so an identifier named `colour` or a `serialise()`
# method is never flagged and never renamed.
#
# Generated output is excluded: it is machine-written from these same sources.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔤 Checking US spelling in Markdown..."
echo ""

if ! command -v python3 &> /dev/null; then
  echo "❌ python3 not installed"
  exit 1
fi

mapfile -t md_files < <(git ls-files '*.md' | grep -v '^hosts/[^/]*/generated/' | sort)

if [ "${#md_files[@]}" -eq 0 ]; then
  echo "⚠️  No Markdown files found"
  exit 0
fi

gha_group "${#md_files[@]} Markdown file(s) to scan"
for file in "${md_files[@]}"; do
  echo "  • $file"
done
gha_endgroup

set +e
output="$(python3 scripts/check-us-spelling.py "${md_files[@]}" 2>&1)"
status=$?
set -e

echo "$output"

gha_summary_heading "US spelling"

if [ "$status" -eq 0 ]; then
  echo ""
  echo "✅ US spelling clean across ${#md_files[@]} file(s)"
  gha_summary_result ok "US spelling clean across ${#md_files[@]} file(s)"
  exit 0
fi

# The scanner prints a bare path on its own line, then indented hits beneath it.
# Re-emit each hit as an annotation so it lands on the diff.
current=""
while IFS= read -r line; do
  case "$line" in
    "  "*"->"*)
      number="$(printf '%s' "$line" | awk '{print $1}')"
      found="$(printf '%s' "$line" | awk '{print $2}')"
      want="$(printf '%s' "$line" | awk '{print $4}')"
      gha_error "British spelling '${found}' - use '${want}'" "$current" "$number"
      ;;
    "  "*) : ;;
    ?*) current="$line" ;;
  esac
done <<< "$output"

gha_summary_result fail "British spellings found - see the log for file and line"

echo ""
echo "Fix the spellings above, or add a legitimate exception to scripts/check-us-spelling.py."
exit 1
