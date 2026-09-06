#!/usr/bin/env bash

# ========================================================================
# GitHub Actions Helpers
# ========================================================================
# Emit GitHub Actions log groups, annotations and job summaries.
#
# Every function is a no-op outside Actions, so scripts using them behave
# identically when run locally via `mise run`. Nothing here writes to stdout
# when GITHUB_ACTIONS is unset - the human-readable output stays whatever the
# calling script already prints.
#
# Usage: source this file near the top of your script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "${SCRIPT_DIR}/../../scripts/gha-helpers.sh"
#
# Job summaries render as Markdown on the run's summary page, which is where
# "what passed and what didn't" is meant to be read at a glance. The logs are
# for the detail behind a failure.
# ========================================================================

# True when running inside a GitHub Actions runner.
gha_enabled() {
  [ "${GITHUB_ACTIONS:-}" = "true" ]
}

# True when a job summary file is available to append to.
gha_summary_enabled() {
  gha_enabled && [ -n "${GITHUB_STEP_SUMMARY:-}" ]
}

# ------------------------------------------------------------------------
# Log groups - collapsible sections in the run log
# ------------------------------------------------------------------------

gha_group() {
  gha_enabled && echo "::group::$1"
  return 0
}

gha_endgroup() {
  gha_enabled && echo "::endgroup::"
  return 0
}

# ------------------------------------------------------------------------
# Annotations - surfaced at the top of the run and inline on the diff
# ------------------------------------------------------------------------

# gha_error <message> [file] [line]
gha_error() {
  local message="$1" file="${2:-}" line="${3:-}"
  if gha_enabled; then
    if [ -n "$file" ] && [ -n "$line" ]; then
      echo "::error file=${file},line=${line}::${message}"
    elif [ -n "$file" ]; then
      echo "::error file=${file}::${message}"
    else
      echo "::error::${message}"
    fi
  fi
  return 0
}

# gha_warning <message> [file]
gha_warning() {
  local message="$1" file="${2:-}"
  if gha_enabled; then
    if [ -n "$file" ]; then
      echo "::warning file=${file}::${message}"
    else
      echo "::warning::${message}"
    fi
  fi
  return 0
}

# ------------------------------------------------------------------------
# Job summary - Markdown on the run summary page
# ------------------------------------------------------------------------

# Append a raw Markdown line.
gha_summary() {
  gha_summary_enabled && printf '%s\n' "$1" >> "$GITHUB_STEP_SUMMARY"
  return 0
}

# gha_summary_heading <text> - a section heading with a pass/fail marker
gha_summary_heading() {
  gha_summary ""
  gha_summary "## $1"
  gha_summary ""
  return 0
}

# gha_summary_table <header-cells...> - opens a table with the given columns
gha_summary_table() {
  local header="|" divider="|"
  local cell
  for cell in "$@"; do
    header="${header} ${cell} |"
    divider="${divider} --- |"
  done
  gha_summary "$header"
  gha_summary "$divider"
  return 0
}

# gha_summary_row <cells...>
gha_summary_row() {
  local row="|"
  local cell
  for cell in "$@"; do
    row="${row} ${cell} |"
  done
  gha_summary "$row"
  return 0
}

# gha_summary_result <ok|fail> <summary line> - a bolded verdict line
gha_summary_result() {
  local status="$1" message="$2"
  gha_summary ""
  if [ "$status" = "ok" ]; then
    gha_summary "**✅ ${message}**"
  else
    gha_summary "**❌ ${message}**"
  fi
  return 0
}
