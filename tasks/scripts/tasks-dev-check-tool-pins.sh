#!/usr/bin/env bash
set -euo pipefail

# Check that each mise lockfile records the exact versions pinned in its
# config: mise.toml against mise.lock, and the global config the dotfiles
# deploy to ~/.config/mise against its own mise.lock.
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
# Only exact pins are compared, including prereleases ("1.0.0-beta.12"). A
# range or alias ("latest", "3", "3.14.x") is expected to resolve to something
# different and is reported as skipped.

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🔍 Checking mise pins against their lockfiles..."
echo ""

for cmd in taplo jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "❌ $cmd is required but not on PATH"
    exit 1
  fi
done

# Each pair is a config file, its lockfile, and the command that regenerates
# the lockfile. The global pair is what `mise install --locked` reads for the
# tools in ~/.config/mise/config.toml.
pairs=(
  "mise.toml|mise.lock|mise lock"
  "apps/mise/dotfiles/config.toml|apps/mise/dotfiles/mise.lock|mise run dev:lock-global"
)

gha_summary_heading "Tool pins (config vs lockfile)"
gha_summary_table "" "Tool" "Config" "Lockfile"

failures=0
checked=0
for pair in "${pairs[@]}"; do
  IFS='|' read -r config lockfile relock <<< "$pair"

  for file in "$config" "$lockfile"; do
    if [ ! -f "$file" ]; then
      echo "❌ $file not found"
      exit 1
    fi
  done

  echo "$config vs $lockfile"

  # { "<tool>": "<pin>" } - the [tools] table of the config
  pinned="$(taplo get -o json 'tools' -f "$config")"

  # { "<tool>": "<locked version>" } - each [[tools.<name>]] array entry
  locked="$(taplo get -o json 'tools' -f "$lockfile" |
    jq 'with_entries(.value |= (if type == "array" then .[0].version else .version end))')"

  report="$(jq -rn --argjson pinned "$pinned" --argjson locked "$locked" '
    $pinned
    | to_entries[]
    # A pin is either a bare string ("1.2.3") or mise'"'"'s table form
    # ({ version = "1.2.3", ... }). Normalize before comparing; anything else
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
      elif ($entry.value | test("^[0-9]+\\.[0-9]+(\\.[0-9]+)?(-[0-9A-Za-z.]+)?$") | not) then
        "SKIP\t\($entry.key)\t\($entry.value)\t(not an exact pin)"
      elif $lock == null then
        "FAIL\t\($entry.key)\t\($entry.value)\t(missing from the lockfile)"
      elif $lock != $entry.value then
        "FAIL\t\($entry.key)\t\($entry.value)\t\($lock)"
      else
        "OK\t\($entry.key)\t\($entry.value)\t\($lock)"
      end
  ')"

  pair_failures=0
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
        pair_failures=$((pair_failures + 1))
        printf '  ❌ %-34s config=%-12s lockfile=%s\n' "$tool" "$pin" "$lock"
        gha_summary_row "❌" "\`$tool\`" "**$pin**" "**$lock**"
        gha_error "$tool: $config pins $pin but $lockfile records $lock - run '$relock'" "$config"
        ;;
    esac
  done <<< "$report"

  if [ "$pair_failures" -gt 0 ]; then
    echo "  Run '$relock' to regenerate $lockfile from $config."
  fi
  failures=$((failures + pair_failures))
  echo ""
done

if [ "$failures" -eq 0 ]; then
  echo "✅ All $checked exact pin(s) match their lockfiles"
  gha_summary_result ok "All $checked exact pin(s) match their lockfiles"
else
  gha_summary_result fail "$failures of $checked exact pin(s) disagree with their lockfiles"
  echo "❌ $failures of $checked exact pin(s) disagree with their lockfiles"
  exit 1
fi
