#!/usr/bin/env bash
# Claude Code statusline. JSON on stdin -> single colored line on stdout.
# Spec: https://code.claude.com/docs/en/statusline

set -u

input="$(cat)"

j() {
  printf '%s' "${input}" | jq -r "${1}" 2> /dev/null
}

RESET=$'\033[0m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
BLUE=$'\033[34m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'

model="$(j '.model.display_name // "claude"')"
cwd="$(j '.workspace.current_dir // .cwd // empty')"
style="$(j '.output_style.name // ""')"
ctx_pct="$(j '.context_window.used_percentage // 0' | awk '{printf "%d", $1}')"
cost="$(j '.cost.total_cost_usd // 0' | awk '{printf "%.2f", $1}')"

# Shorten cwd: $HOME -> ~, then keep last 2 path components if deeper than 3
dir="${cwd/#${HOME}/\~}"
depth=$(awk -F/ '{print NF - 1}' <<< "${dir}")
if [ "${depth}" -gt 3 ]; then
  dir="…/$(basename "$(dirname "${cwd}")")/$(basename "${cwd}")"
fi

branch=""
if [ -n "${cwd}" ] && (cd "${cwd}" 2> /dev/null && git rev-parse --git-dir > /dev/null 2>&1); then
  branch="$(cd "${cwd}" && git branch --show-current 2> /dev/null || true)"
fi

out="${BOLD}${CYAN}${model}${RESET}"
out+=" ${BLUE}${dir}${RESET}"
[ -n "${branch}" ] && out+=" ${DIM}|${RESET} ${MAGENTA}${branch}${RESET}"
[ -n "${style}" ] && [ "${style}" != "default" ] && out+=" ${DIM}|${RESET} ${YELLOW}${style}${RESET}"
out+=" ${DIM}|${RESET} ${GREEN}ctx ${ctx_pct}%${RESET}"
out+=" ${DIM}|${RESET} ${DIM}\$${cost}${RESET}"

printf '%b' "${out}"
