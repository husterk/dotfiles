#!/usr/bin/env bash
set -euo pipefail

# Check that mise.lock records the exact versions pinned in mise.toml
#
# `mise install --locked` proves the lockfile's checksums are valid, but not
# that the locked version is the one mise.toml asked for. The two drift apart
# when mise.toml is hand-edited without re-running `mise lock`, leaving a
# lockfile that installs cleanly while silently pinning the wrong version.
#
# The two files are compared directly rather than via `mise ls`: mise re-
# resolves the request at query time, so `requested_version` and `version`
# always agree there and the comparison would be vacuous.
#
# Only exact pins are compared. A range or alias ("latest", "3", "3.14.x") is
# expected to resolve to something different and is reported as skipped.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔍 Checking mise.toml pins against mise.lock..."
echo ""

for cmd in taplo jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ $cmd is required but not on PATH"
    exit 1
  fi
done

for file in mise.toml mise.lock; do
  if [ ! -f "$file" ]; then
    echo "❌ $file not found"
    exit 1
  fi
done

# { "<tool>": "<pin>" } - the [tools] table of mise.toml
pinned="$(taplo get -o json 'tools' -f mise.toml)"

# { "<tool>": "<locked version>" } - each [[tools.<name>]] array entry
locked="$(taplo get -o json 'tools' -f mise.lock |
  jq 'with_entries(.value |= (if type == "array" then .[0].version else .version end))')"

report="$(jq -rn --argjson pinned "$pinned" --argjson locked "$locked" '
  $pinned
  | to_entries[]
  # A pin is either a bare string ("1.2.3") or mise'"'"'s table form
  # ({ version = "1.2.3", ... }). Normalise before comparing; anything else
  # has no version to check.
  | {
      key: .key,
      value: (if (.value | type) == "string" then .value
              elif (.value | type) == "object" then (.value.version // null)
              else null end)
    }
  | . as $entry
  | ($locked[$entry.key]) as $lock
  | if $entry.value == null then
      "SKIP\t\($entry.key)\t-\t(no version to check)"
    elif ($entry.value | test("^[0-9]+\\.[0-9]+(\\.[0-9]+)?$") | not) then
      "SKIP\t\($entry.key)\t\($entry.value)\t(not an exact pin)"
    elif $lock == null then
      "FAIL\t\($entry.key)\t\($entry.value)\t(missing from mise.lock)"
    elif $lock != $entry.value then
      "FAIL\t\($entry.key)\t\($entry.value)\t\($lock)"
    else
      "OK\t\($entry.key)\t\($entry.value)\t\($lock)"
    end
')"

gha_summary_heading "Tool pins (mise.toml vs mise.lock)"
gha_summary_table "" "Tool" "mise.toml" "mise.lock"

failures=0
checked=0
while IFS=$'\t' read -r status tool pin lock; do
  case "$status" in
    OK)
      checked=$((checked + 1))
      printf '  ✅ %-34s %s\n' "$tool" "$pin"
      gha_summary_row "✅" "\`$tool\`" "$pin" "$lock"
      ;;
    SKIP)
      printf '  ⏭️  %-34s %-12s %s\n' "$tool" "$pin" "$lock"
      gha_summary_row "⏭️" "\`$tool\`" "$pin" "$lock"
      ;;
    FAIL)
      checked=$((checked + 1))
      failures=$((failures + 1))
      printf '  ❌ %-34s mise.toml=%-12s mise.lock=%s\n' "$tool" "$pin" "$lock"
      gha_summary_row "❌" "\`$tool\`" "**$pin**" "**$lock**"
      gha_error "$tool: mise.toml pins $pin but mise.lock records $lock - run 'mise lock'" "mise.toml"
      ;;
  esac
done <<< "$report"

echo ""

if [ "$failures" -eq 0 ]; then
  echo "✅ All $checked exact pin(s) match mise.lock"
  gha_summary_result ok "All $checked exact pin(s) match mise.lock"
else
  gha_summary_result fail "$failures of $checked exact pin(s) disagree with mise.lock"
  echo "❌ $failures of $checked exact pin(s) disagree with mise.lock"
  echo ""
  echo "Run 'mise lock' to regenerate the lockfile from mise.toml."
  exit 1
fi
