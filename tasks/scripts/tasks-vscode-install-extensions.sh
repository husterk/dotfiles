#!/usr/bin/env bash
set -euo pipefail

# Install required VSCode extensions.
# VSCode itself is installed via Homebrew cask by `mise run nix:apply`,
# so this task is sequenced after nix:apply in the composite `setup` /
# `refresh` flows. If `code` is not on PATH yet (e.g. first bootstrap),
# skip gracefully instead of failing the composite task.

EXTENSIONS=(
  anthropic.claude-code
)

if ! command -v code > /dev/null 2>&1; then
  echo "⏭️  Skipping VSCode extensions: 'code' not on PATH (install VSCode first via nix:apply)."
  exit 0
fi

echo "🧩 Installing VSCode extensions..."
for ext in "${EXTENSIONS[@]}"; do
  echo "  • $ext"
  code --install-extension "$ext" --force > /dev/null
done
echo "✅ VSCode extensions installed!"
