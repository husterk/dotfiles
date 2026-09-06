#!/usr/bin/env bash
set -euo pipefail

# Validate Claude Code skill and agent definitions
#
# Checks frontmatter validity, that a skill's `name` still matches its
# directory, that every file a SKILL.md cites exists, and that no file sits in a
# skill directory unreferenced. These break silently: a skill with bad
# frontmatter is simply never loaded.
#
# Two trees are audited: .claude/ (project-scoped skills for this repo) and
# apps/claude/dotfiles/ (the source deployed to ~/.claude).

REPO_ROOT="${1:?REPO_ROOT required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source-path=SCRIPTDIR
# shellcheck source=../../scripts/gha-helpers.sh
source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"

cd "$REPO_ROOT"

echo "🧩 Validating Claude skills and agents..."
echo ""

if ! command -v python3 &> /dev/null; then
  echo "❌ python3 not installed"
  exit 1
fi

roots=()
for candidate in .claude apps/claude/dotfiles; do
  if [ -d "$candidate/skills" ] || [ -d "$candidate/agents" ]; then
    roots+=("$candidate")
  fi
done

if [ "${#roots[@]}" -eq 0 ]; then
  echo "⚠️  No skills/ or agents/ directories found"
  exit 0
fi

gha_group "Trees audited"
for root in "${roots[@]}"; do
  echo "  • $root"
done
gha_endgroup

set +e
output="$(python3 scripts/check-skills.py "${roots[@]}" 2>&1)"
status=$?
set -e

echo "$output"

gha_summary_heading "Claude skills and agents"

if [ "$status" -eq 0 ]; then
  echo ""
  echo "✅ All skill and agent definitions valid"
  gha_summary_result ok "$(printf '%s' "$output" | tr -s ' ' | sed 's/^ *PASS *//')"
  exit 0
fi

# A bare path on its own line, then indented problems beneath it.
current=""
problems=0
gha_summary_table "" "File" "Problem"
while IFS= read -r line; do
  case "$line" in
    "    "*)
      gha_error "${line#    }" "$current"
      gha_summary_row "❌" "\`$current\`" "${line#    }"
      problems=$((problems + 1))
      ;;
    "  "*) : ;;
    ?*) current="$line" ;;
  esac
done <<< "$output"

gha_summary_result fail "$problems problem(s) in skill or agent definitions"

echo ""
echo "Fix the problems above before merging."
exit 1
