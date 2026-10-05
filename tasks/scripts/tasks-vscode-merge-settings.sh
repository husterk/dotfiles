#!/usr/bin/env bash
# Merge a JSON fragment into VSCode's settings.json non-destructively.
# Keys from the fragment win, RETIRED keys are removed, and every other key
# already in settings.json is preserved.
#
# VSCode's settings.json is JSONC (allows // and /* */ comments). We try
# vanilla jq first, then fall back to a string-aware JSONC stripper before
# parsing. We never silently default to {} on parse failure — that would
# discard the user's existing settings.
#
# Usage: tasks-vscode-merge-settings.sh <config-root>

set -euo pipefail

CONFIG_ROOT="${1:?usage: $0 <config-root>}"
FRAGMENT_FILE="$CONFIG_ROOT/apps/visual-studio-code/vscode-settings-fragment.json"
SETTINGS_FILE="$HOME/Library/Application Support/Code/User/settings.json"
# Keys the fragment used to set and has since dropped. initialPermissionMode
# pins every new conversation to one mode and cannot be set to auto, so the
# extension can start in auto mode only once the key is gone.
RETIRED='["claudeCode.initialPermissionMode"]'

if [[ ! -f "$FRAGMENT_FILE" ]]; then
  echo "❌ VSCode settings fragment not found: $FRAGMENT_FILE" >&2
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "❌ jq is required but not on PATH" >&2
  exit 1
fi

# Strip JSONC comments and trailing commas while respecting string literals.
# VSCode allows both; vanilla JSON forbids both. Reads stdin → stdout.
strip_jsonc() {
  python3 -c '
import re, sys
src = sys.stdin.read()
out = []
i = 0
n = len(src)
in_string = False
while i < n:
    c = src[i]
    nxt = src[i + 1] if i + 1 < n else ""
    if in_string:
        out.append(c)
        if c == "\\" and nxt:
            out.append(nxt)
            i += 2
            continue
        if c == "\"":
            in_string = False
        i += 1
        continue
    if c == "\"":
        in_string = True
        out.append(c)
        i += 1
        continue
    if c == "/" and nxt == "/":
        while i < n and src[i] != "\n":
            i += 1
        continue
    if c == "/" and nxt == "*":
        i += 2
        while i < n - 1 and not (src[i] == "*" and src[i + 1] == "/"):
            i += 1
        i += 2
        continue
    out.append(c)
    i += 1
stripped = "".join(out)
# Remove trailing commas inside objects/arrays, e.g. {"a": 1,} → {"a": 1}.
# Safe to run on the comment-stripped output because all remaining strings
# are still escaped/protected by JSON tokenization rules.
stripped = re.sub(r",(\s*[}\]])", r"\1", stripped)
sys.stdout.write(stripped)
'
}

echo "🧩 Merging Claude Code + Copilot settings into VSCode settings.json..."

# Create from fragment if settings.json doesn't exist
if [[ ! -f "$SETTINGS_FILE" ]]; then
  mkdir -p "$(dirname "$SETTINGS_FILE")"
  cp -a "$FRAGMENT_FILE" "$SETTINGS_FILE"
  echo "  → created $SETTINGS_FILE"
  exit 0
fi

# Parse existing settings — vanilla JSON first, then JSONC.
if existing_json=$(jq '.' "$SETTINGS_FILE" 2> /dev/null); then
  :
elif existing_json=$(strip_jsonc < "$SETTINGS_FILE" | jq '.' 2> /dev/null); then
  :
else
  echo "  ❌ Could not parse $SETTINGS_FILE as JSON or JSONC." >&2
  echo "     Fix or remove the file and re-run. Settings were NOT modified." >&2
  exit 1
fi

fragment_json=$(jq '.' "$FRAGMENT_FILE")
merged_json=$(echo "$existing_json" | jq --argjson fragment "$fragment_json" --argjson retired "$RETIRED" \
  '(. * $fragment) | delpaths([$retired[] | [.]])')

if [[ "$existing_json" == "$merged_json" ]]; then
  echo "  ✓ already up to date"
  exit 0
fi

# Back up before writing
backup="${SETTINGS_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
cp -a "$SETTINGS_FILE" "$backup"
echo "  → backup: $backup"

echo "$merged_json" | jq '.' > "$SETTINGS_FILE"
echo "  → updated"
