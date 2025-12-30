#!/usr/bin/env bash
set -euo pipefail

# Compare source dotfiles with currently deployed versions
# Respects .gitignore files in app dotfiles directories

HOST_DIR="${1:?HOST_DIR required}"
REPO_ROOT="${2:?REPO_ROOT required}"

echo "📊 Comparing dotfiles..."
echo ""

if [ ! -d "$HOST_DIR/generated/dotfiles/.config" ]; then
  echo "⚠️  No generated dotfiles found"
  exit 0
fi

# Function to check if a file should be ignored
should_ignore() {
  local file="$1"
  local gitignore="$2"
  local base_name
  base_name=$(basename "$file")

  # If no .gitignore, don't ignore
  [ -z "$gitignore" ] && return 1

  # Check each pattern in .gitignore
  while IFS= read -r pattern; do
    # Skip empty lines and comments
    [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue

    # Trim whitespace
    pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    [ -z "$pattern" ] && continue

    # Check for exact basename match first
    if [[ "$base_name" == "$pattern" ]]; then
      return 0
    fi

    # Check for wildcard pattern match (basic glob)
    # shellcheck disable=SC2053
    if [[ "$base_name" == $pattern ]]; then
      return 0
    fi

    # Check for directory patterns (ending with /)
    if [[ "$pattern" == */ ]]; then
      local dir_pattern="${pattern%/}"
      if [[ "$file" == "$dir_pattern"* ]] || [[ "$file" == *"/$dir_pattern"* ]]; then
        return 0
      fi
    fi

    # Check if pattern matches the relative path
    # shellcheck disable=SC2053
    if [[ "$file" == $pattern ]] || [[ "$file" == *"/$pattern" ]]; then
      return 0
    fi
  done <"$gitignore"

  return 1
}

for app_dir in "$HOST_DIR"/generated/dotfiles/.config/*; do
  if [ ! -d "$app_dir" ]; then
    continue
  fi

  app_name=$(basename "$app_dir")
  if [ ! -d "$HOME/.config/$app_name" ]; then
    continue
  fi

  echo "=== $app_name ==="

  # Find the source app directory to check for .gitignore
  SOURCE_APP_DIR=""
  GITIGNORE_FILE=""

  # Build mapping from config directory name to source path using manifest
  if [ -f "$HOST_DIR/host-manifest.yml" ]; then
    # Find the app and source path that has a dotfiles target matching ~/.config/$app_name/
    manifest_data=$(yq eval ".apps[] | select(.dotfiles != null) | select(.dotfiles[].target == \"~/.config/$app_name/\") | .name + \"|\" + .dotfiles[].source" "$HOST_DIR/host-manifest.yml" 2>/dev/null | head -1)

    if [ -n "$manifest_data" ]; then
      manifest_source="${manifest_data#*|}"

      # Extract the source directory path (remove glob patterns)
      manifest_source_dir="$manifest_source"
      # Remove /**/* or /** or /*
      manifest_source_dir="${manifest_source_dir%%/\*\**}"
      manifest_source_dir="${manifest_source_dir%%/\**}"
      manifest_source_dir="${manifest_source_dir%%/\*}"

      # Build the full source directory path
      SOURCE_APP_DIR="$REPO_ROOT$manifest_source_dir"
    fi
  fi

  # Fallback to exact match if manifest lookup failed
  if [ -z "$SOURCE_APP_DIR" ] && [ -d "$REPO_ROOT/apps/$app_name/dotfiles" ]; then
    SOURCE_APP_DIR="$REPO_ROOT/apps/$app_name/dotfiles"
  fi

  if [ -n "$SOURCE_APP_DIR" ] && [ -f "$SOURCE_APP_DIR/.gitignore" ]; then
    GITIGNORE_FILE="$SOURCE_APP_DIR/.gitignore"
  fi

  # Compare files recursively, respecting .gitignore
  has_diff=false
  # Use find with proper IFS handling for filenames with spaces
  while IFS= read -r generated_file; do
    # Get relative path from generated directory
    rel_path="${generated_file#"$app_dir"/}"
    deployed_file="$HOME/.config/$app_name/$rel_path"

    # Check if file should be ignored
    if [ -n "$GITIGNORE_FILE" ] && should_ignore "$rel_path" "$GITIGNORE_FILE"; then
      continue
    fi

    # Check if file exists in deployed location
    if [ ! -f "$deployed_file" ]; then
      has_diff=true
      echo "Only in generated: $rel_path"
    elif ! diff -q "$generated_file" "$deployed_file" >/dev/null 2>&1; then
      has_diff=true
      echo "Files differ: $rel_path"
      diff -u --color=always "$generated_file" "$deployed_file" 2>/dev/null || true
    fi
  done < <(find "$app_dir" -type f)

  # Check for files in deployed that don't exist in generated
  while IFS= read -r deployed_file; do
    rel_path="${deployed_file#"$HOME"/.config/"$app_name"/}"
    generated_file="$app_dir/$rel_path"

    # Check if file should be ignored
    if [ -n "$GITIGNORE_FILE" ] && should_ignore "$rel_path" "$GITIGNORE_FILE"; then
      continue
    fi

    if [ ! -f "$generated_file" ]; then
      has_diff=true
      echo "Only in deployed: $rel_path"
    fi
  done < <(find "$HOME/.config/$app_name" -type f 2>/dev/null)

  if [ "$has_diff" = false ]; then
    echo "No differences found (ignored files excluded)"
  fi

  echo ""
done
