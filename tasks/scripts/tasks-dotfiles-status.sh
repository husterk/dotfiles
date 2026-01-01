#!/usr/bin/env bash
set -euo pipefail

# Show dotfile deployment status
# Lists which files are symlinked, grouped by app

HOST_DIR="${1:?HOST_DIR required}"
HOST_MANIFEST="$HOST_DIR/host-manifest.yml"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     Dotfiles Status                              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -d "$HOST_DIR/generated/dotfiles" ]; then
  echo "⚠️  No generated dotfiles found"
  echo "   Run: task bootstrap:generate-dotfiles"
  echo ""
  exit 0
fi

echo "📁 Generated Dotfiles:"
echo "  Location: $HOST_DIR/generated/dotfiles"
echo ""

if ! command -v yq &>/dev/null; then
  echo "⚠️  yq not installed - showing directory names only"
  for app in "$HOST_DIR"/generated/dotfiles/.config/*; do
    if [ -d "$app" ]; then
      echo "  • $(basename "$app")"
    fi
  done
else
  # Build a map of target paths to app names
  declare -A target_to_app

  # shellcheck disable=SC2016
  while IFS='|' read -r app_name target; do
    # Normalize target path (remove ~/ prefix, trailing slash)
    target_normalized="${target#\~/}"
    target_normalized="${target_normalized%/}"
    # Handle .config paths
    if [[ "$target_normalized" == .config/* ]]; then
      config_dir=$(echo "$target_normalized" | cut -d'/' -f2)
      target_to_app["$config_dir"]="$app_name"
    fi
  done < <(yq eval '.apps[] | select(.dotfiles != null) | .name as $app | .dotfiles[] | $app + "|" + .target' "$HOST_MANIFEST" 2>/dev/null)

  # Process each app
  for app_dir in "$HOST_DIR"/generated/dotfiles/.config/*; do
    if [ ! -d "$app_dir" ]; then
      continue
    fi

    config_name=$(basename "$app_dir")
    app_name="${target_to_app[$config_name]:-$config_name}"

    echo "  📦 $app_name"

    # Find stowed files for this app
    cd "$HOME" || continue
    found_files=false

    while IFS= read -r link; do
      if [ -L "$link" ]; then
        target=$(readlink "$link")
        if echo "$target" | grep -q "dotfiles.*generated.*dotfiles"; then
          # Check if this link belongs to this app's config directory
          rel_link="${link#"$HOME"/}"
          if [[ "$rel_link" == .config/$config_name/* ]]; then
            if [ "$found_files" = false ]; then
              found_files=true
            fi
            # Show the full path relative to home
            echo "      ✓ ~/$rel_link"
          fi
        fi
      fi
    done < <(find ".config/$config_name" -type l 2>/dev/null)

    if [ "$found_files" = false ]; then
      echo "      ⚠️  No stowed files"
    fi
  done
fi
echo ""

echo "💾 Backups:"
if [ -d "$HOST_DIR/generated" ]; then
  backup_count=$(find "$HOST_DIR/generated" -maxdepth 1 -name "dotfiles-backup-*" -type d 2>/dev/null | wc -l)
  if [ "$backup_count" -gt 0 ]; then
    echo "  Found $backup_count backup(s):"
    find "$HOST_DIR/generated" -maxdepth 1 -name "dotfiles-backup-*" -type d 2>/dev/null | sort -r | head -5 | while read -r backup; do
      echo "    • $(basename "$backup")"
    done
    if [ "$backup_count" -gt 5 ]; then
      echo "    ... and $((backup_count - 5)) more"
    fi
  else
    echo "  No backups found"
  fi
fi
echo ""
