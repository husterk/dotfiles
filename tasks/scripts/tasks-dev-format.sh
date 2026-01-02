#!/usr/bin/env bash
set -euo pipefail

# Format all files using treefmt

REPO_ROOT="${1:?REPO_ROOT required}"

cd "$REPO_ROOT"

if ! command -v treefmt &> /dev/null; then
  echo "❌ treefmt not installed"
  exit 1
fi

echo "✨ Formatting all files with treefmt..."
echo ""

# Show configured formatters from treefmt.toml
if [ -f treefmt.toml ]; then
  echo "Configured formatters:"
  # Extract formatter names and file patterns from treefmt.toml
  awk '
    /^\[formatter\./ {
      name = substr($0, 12, length($0) - 12)
      in_formatter = 1
      command = ""
      includes = ""
    }
    in_formatter && /^command/ {
      match($0, /"[^"]+/)
      command = substr($0, RSTART+1, RLENGTH-2)
    }
    in_formatter && /^includes/ {
      match($0, /\[.*\]/)
      includes = substr($0, RSTART+1, RLENGTH-2)
      gsub(/"/, "", includes)
    }
    /^$/ && in_formatter {
      if (name && command) {
        printf "  • %s (%s) → %s\n", name, command, includes
      }
      in_formatter = 0
    }
  ' treefmt.toml
  echo ""
fi

# Run treefmt and capture output
# treefmt outputs files that were formatted to stderr
temp_output=$(mktemp)
if treefmt --verbose 2>&1 | tee "$temp_output"; then
  # Check if any files were formatted
  if grep -q "formatted" "$temp_output" 2> /dev/null; then
    echo ""
    echo "Reformatted files:"
    grep "formatted" "$temp_output" | sed 's/^/  ✓ /'
    echo ""
    echo "✅ Formatting complete"
  else
    echo "✅ All files already formatted"
  fi
else
  echo ""
  echo "✅ Formatting complete"
fi

rm -f "$temp_output"
