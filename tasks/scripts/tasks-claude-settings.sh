#!/usr/bin/env bash
set -euo pipefail

# Manage ~/.claude/settings.json as a merge rather than a Stow symlink.
#
# AoE rewrites the hooks in that file, and Claude Code writes keys such as
# model into it, so it cannot be a read-only symlink into generated
# output. The repo owns the keys in apps/claude/settings.base.json; the live
# file keeps everything else.
#
# Usage: tasks-claude-settings.sh <materialize|merge> <config_root>
#   materialize  Replace a symlinked settings.json with a regular file holding
#                the same content. Must run before dotfiles:generate deletes
#                the symlink's target.
#   merge        Write live + base: base keys win, other live keys (such as
#                hooks) stay, and RETIRED keys are removed.

MODE="${1:?mode required: materialize or merge}"
CONFIG_ROOT="${2:?config_root required}"

LIVE="$HOME/.claude/settings.json"
BASE="$CONFIG_ROOT/apps/claude/settings.base.json"
# Keys the repo used to set and has since dropped.
RETIRED='["skipDangerousModePermissionPrompt"]'

# Act only for the checkout that deployed ~/.claude. An agent worktree running
# dotfiles:generate must not touch the live file.
deployed_root() {
  local link="$HOME/.claude/CLAUDE.md"
  [ -L "$link" ] || return 1
  (cd "$HOME/.claude" && cd "$(dirname "$(readlink "$link")")" && pwd -P)
}
owner="$(deployed_root || true)"
root="$(cd "$CONFIG_ROOT" && pwd -P)"
if [ -z "$owner" ] || [[ "$owner" != "$root"/hosts/* ]]; then
  echo "⏭️  claude:$MODE skipped: ~/.claude is not deployed from $CONFIG_ROOT"
  exit 0
fi

case "$MODE" in
  materialize)
    if [ -L "$LIVE" ]; then
      tmp="$(mktemp "$HOME/.claude/settings.json.XXXXXX")"
      if [ -e "$LIVE" ]; then
        cat "$LIVE" > "$tmp"
      else
        echo '{}' > "$tmp"
      fi
      mv "$tmp" "$LIVE"
      echo "✅ ~/.claude/settings.json is now a regular file"
    fi
    ;;
  merge)
    live='{}'
    if [ -s "$LIVE" ]; then
      if ! live="$(jq -c . "$LIVE" 2> /dev/null)"; then
        echo "❌ $LIVE is not valid JSON; fix it by hand, nothing was written"
        exit 1
      fi
    fi
    cp -p "$LIVE" "$LIVE.bak" 2> /dev/null || true
    tmp="$(mktemp "$HOME/.claude/settings.json.XXXXXX")"
    jq -S --argjson live "$live" --argjson retired "$RETIRED" \
      '($live + .) | delpaths([$retired[] | [.]])' "$BASE" > "$tmp"
    mv "$tmp" "$LIVE"
    echo "✅ Merged $BASE into ~/.claude/settings.json"
    ;;
  *)
    echo "Unknown mode: $MODE" >&2
    exit 2
    ;;
esac
