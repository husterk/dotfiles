#!/usr/bin/env bash
set -euo pipefail

# Remove all dotfile backups for the current host

HOST_DIR="${1:?HOST_DIR required}"

echo "🗑️  Removing backups..."

count=0
for backup in "$HOST_DIR"/generated/dotfiles-backup-*; do
  if [ -d "$backup" ]; then
    rm -rf "$backup"
    echo "  ✓ Removed $(basename "$backup")"
    count=$((count + 1))
  fi
done

if [ "$count" -eq 0 ]; then
  echo "  No backups found"
else
  echo "✅ Removed $count backup(s)"
fi
