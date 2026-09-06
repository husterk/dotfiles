#!/bin/bash
# Claude Code status line: two-line display.
#   Line 1 (identity + location): model·effort, fast-mode, dir, git branch + dirty counts, clickable PR badge
#   Line 2 (session metrics):      context bar + %, tokens/window, cost, lines +/-, duration
# All session fields come from a single jq pass over stdin; git state is cached per session for 5s.

input=$(cat)

# --- single jq pass: one field per line, read into an array (bash 3.2 compatible;
#     the while-loop preserves empty fields, which tab/space IFS `read` would collapse) ---
F=()
while IFS= read -r line; do F+=("$line"); done < <(
  echo "$input" | jq -r '
    .model.display_name                       // "Claude",
    (.effort.level                            // ""),
    (.fast_mode                               // false | tostring),
    (.workspace.current_dir // .cwd           // ""),
    (.session_id                              // "unknown"),
    (.context_window.used_percentage          // 0 | floor),
    (.context_window.total_input_tokens       // 0),
    (.context_window.context_window_size      // 200000),
    (.cost.total_cost_usd                     // 0),
    (.cost.total_duration_ms                  // 0),
    (.cost.total_lines_added                  // 0),
    (.cost.total_lines_removed                // 0),
    (.pr.number                               // ""),
    (.pr.url                                  // ""),
    (.pr.review_state                         // "")'
)
MODEL="${F[0]}"
EFFORT="${F[1]}"
FAST="${F[2]}"
DIR="${F[3]}"
SESSION_ID="${F[4]}"
PCT="${F[5]}"
TOKENS="${F[6]}"
WIN="${F[7]}"
COST="${F[8]}"
DURATION_MS="${F[9]}"
LINES_ADD="${F[10]}"
LINES_DEL="${F[11]}"
PR_NUM="${F[12]}"
PR_URL="${F[13]}"
PR_STATE="${F[14]}"

CYAN='\033[36m'
MAGENTA='\033[35m'
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# --- git info, cached per session for 5s (file counts, not line counts) ---
CACHE_FILE="/tmp/statusline-git-cache-${SESSION_ID}"
CACHE_MAX_AGE=5

cache_is_stale() {
  [ ! -f "$CACHE_FILE" ] ||
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2> /dev/null || stat -c %Y "$CACHE_FILE" 2> /dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}

if cache_is_stale; then
  if [ -n "$DIR" ] && git -C "$DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$DIR" branch --show-current 2> /dev/null)
    STAGED=$(git -C "$DIR" diff --cached --numstat 2> /dev/null | wc -l | tr -d ' ')
    MODIFIED=$(git -C "$DIR" diff --numstat 2> /dev/null | wc -l | tr -d ' ')
    UNTRACKED=$(git -C "$DIR" ls-files --others --exclude-standard 2> /dev/null | wc -l | tr -d ' ')
    printf '%s|%s|%s|%s\n' "$BRANCH" "$STAGED" "$MODIFIED" "$UNTRACKED" > "$CACHE_FILE"
  else
    printf '|||\n' > "$CACHE_FILE"
  fi
fi

IFS='|' read -r BRANCH STAGED MODIFIED UNTRACKED < "$CACHE_FILE"

# --- helpers ---
fmt_k() { # 126000 -> 126k ; <1000 stays as-is
  local n=${1:-0}
  if [ "$n" -ge 1000 ]; then echo "$((n / 1000))k"; else echo "$n"; fi
}
fmt_win() { # 200000 -> 200k ; 1000000 -> 1M
  local n=${1:-0}
  if [ "$n" -ge 1000000 ]; then echo "$((n / 1000000))M"; else echo "$((n / 1000))k"; fi
}

# --- line 1: model·effort, fast, dir, git, PR ---
LINE1="${CYAN}[${MODEL}"
[ -n "$EFFORT" ] && LINE1="${LINE1}${DIM}·${EFFORT}${RESET}${CYAN}"
LINE1="${LINE1}]${RESET}"
[ "$FAST" = "true" ] && LINE1="${LINE1} ${YELLOW}⚡${RESET}"
LINE1="${LINE1} 📁 ${DIR##*/}"

if [ -n "$BRANCH" ]; then
  GIT_PART=" · ${MAGENTA}🌿 ${BRANCH}${RESET}"
  [ "${STAGED:-0}" -gt 0 ] && GIT_PART="${GIT_PART} ${GREEN}+${STAGED}${RESET}"
  [ "${MODIFIED:-0}" -gt 0 ] && GIT_PART="${GIT_PART} ${YELLOW}~${MODIFIED}${RESET}"
  [ "${UNTRACKED:-0}" -gt 0 ] && GIT_PART="${GIT_PART} ${RED}?${UNTRACKED}${RESET}"
  LINE1="${LINE1}${GIT_PART}"
fi

if [ -n "$PR_NUM" ]; then
  case "$PR_STATE" in
    approved)
      PC="$GREEN"
      PSYM="✓"
      ;;
    changes_requested)
      PC="$RED"
      PSYM="✗"
      ;;
    pending)
      PC="$YELLOW"
      PSYM="○"
      ;;
    draft)
      PC="$DIM"
      PSYM="⊘"
      ;;
    *)
      PC="$BLUE"
      PSYM=""
      ;;
  esac
  PR_TEXT="PR #${PR_NUM}"
  [ -n "$PSYM" ] && PR_TEXT="${PR_TEXT} ${PSYM}"
  if [ -n "$PR_URL" ]; then
    # OSC 8 hyperlink (WezTerm supports it): \e]8;;URL\a TEXT \e]8;;\a
    PR_PART="\033]8;;${PR_URL}\007${PR_TEXT}\033]8;;\007"
  else
    PR_PART="$PR_TEXT"
  fi
  LINE1="${LINE1} · ${PC}${PR_PART}${RESET}"
fi

# --- line 2: context bar + %, tokens/window, cost, lines +/-, duration ---
if [ "$PCT" -ge 90 ]; then
  BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then
  BAR_COLOR="$YELLOW"
else
  BAR_COLOR="$GREEN"
fi

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
[ $FILLED -gt $BAR_WIDTH ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && printf -v FILL "%${FILLED}s" && BAR="${FILL// /█}"
[ "$EMPTY" -gt 0 ] && printf -v PAD "%${EMPTY}s" && BAR="${BAR}${PAD// /░}"

COST_FMT=$(printf '$%.2f' "$COST")
DURATION_SEC=$((DURATION_MS / 1000))
HOURS=$((DURATION_SEC / 3600))
MINS=$(((DURATION_SEC % 3600) / 60))
if [ "$HOURS" -gt 0 ]; then DURATION_FMT="${HOURS}h ${MINS}m"; else DURATION_FMT="${MINS}m"; fi

TOK_FMT="$(fmt_k "$TOKENS")/$(fmt_win "$WIN")"

METRICS="${BAR_COLOR}${BAR}${RESET} ${PCT}%"
METRICS="${METRICS} · ${DIM}${TOK_FMT}${RESET}"
METRICS="${METRICS} · ${YELLOW}${COST_FMT}${RESET}"
if [ "${LINES_ADD:-0}" -gt 0 ] || [ "${LINES_DEL:-0}" -gt 0 ]; then
  METRICS="${METRICS} · ${GREEN}+${LINES_ADD}${RESET}/${RED}-${LINES_DEL}${RESET}"
fi
METRICS="${METRICS} · ${DIM}⏱ ${DURATION_FMT}${RESET}"

# Single line: identity/location/git/PR, then a dim divider, then session metrics.
printf '%b\n' "${LINE1} ${DIM}│${RESET} ${METRICS}"
