#!/usr/bin/env bash

# ========================================================================
# macOS ARM Capture Dotfiles back to Source Script
# ========================================================================
# This script captures changes from generated dotfiles back to source files,
# replacing actual secret values with environment variable placeholders.
#
# Prerequisites: generate-env.sh must be run first to create .env
#
# Usage: ./capture-dotfiles.sh [hostname] [--dry-run]
# Example: ./capture-dotfiles.sh keith-macbook-pro
# Example: ./capture-dotfiles.sh keith-macbook-pro --dry-run
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Load shared script helpers
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "Capture Dotfiles Back" "Captures generated dotfiles back to source with environment variable placeholders"

# ------------------------------------------------------------------------
# Parse Arguments
# ------------------------------------------------------------------------
HOSTNAME="${1:-}"
DRY_RUN=false

# Check for --dry-run flag in any position
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ]; then
    DRY_RUN=true
  fi
done

# Remove --dry-run from arguments to get hostname
if [ "$1" = "--dry-run" ]; then
  HOSTNAME="${2:-}"
elif [ "$2" = "--dry-run" ]; then
  HOSTNAME="$1"
fi

if [ -z "$HOSTNAME" ]; then
  log_error "No hostname provided."
  echo ""
  echo "Usage: $0 <hostname> [--dry-run]"
  echo ""
  echo "Example: $0 keith-macbook-pro"
  echo "Example: $0 keith-macbook-pro --dry-run"
  echo ""
  exit 1
fi

log_info "Capturing dotfiles back to source for host: $HOSTNAME"
if [ "$DRY_RUN" = true ]; then
  log_warning "DRY RUN MODE - No files will be modified"
fi

# ------------------------------------------------------------------------
# Setup and Validate Paths
# ------------------------------------------------------------------------
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"
HOST_MANIFEST="$HOST_DIR/host-manifest.yml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"
GENERATED_DOTFILES_DIR="$GENERATED_DIR/dotfiles"

# Validate required files
if [ ! -d "$HOST_DIR" ]; then
  log_error "Host directory not found: $HOST_DIR"
  exit 1
fi

if [ ! -f "$HOST_MANIFEST" ]; then
  log_error "Host manifest not found: $HOST_MANIFEST"
  exit 1
fi

if [ ! -f "$GENERATED_ENV" ]; then
  log_error "Generated .env file not found: $GENERATED_ENV"
  log_info "Please run: mise run env:generate"
  exit 1
fi

if [ ! -d "$GENERATED_DOTFILES_DIR" ]; then
  log_error "Generated dotfiles directory not found: $GENERATED_DOTFILES_DIR"
  log_info "Please run: mise run dotfiles:generate"
  exit 1
fi

log_success "All required files found."

# ------------------------------------------------------------------------
# Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

if ! command -v yq &> /dev/null; then
  log_error "yq is not installed. Please install yq first."
  exit 1
fi

log_success "All prerequisites verified."

# ------------------------------------------------------------------------
# Build Secret Replacement Map
# ------------------------------------------------------------------------
log_info "Building secret replacement map from .env..."

declare -A SECRET_MAP

# Read .env file and build map of actual_value -> ${VAR_NAME}
while IFS= read -r line || [ -n "$line" ]; do
  # Skip comments and empty lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue

  # Parse VAR=value
  if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
    var_name="${BASH_REMATCH[1]}"
    var_value="${BASH_REMATCH[2]}"

    # Remove surrounding quotes if present
    var_value="${var_value#\"}"
    var_value="${var_value%\"}"
    var_value="${var_value#\'}"
    var_value="${var_value%\'}"

    # Skip empty values
    [[ -z "$var_value" ]] && continue

    # Store value -> placeholder mapping
    SECRET_MAP["$var_value"]="\${$var_name}"
  fi
done < "$GENERATED_ENV"

log_success "Found ${#SECRET_MAP[@]} environment variables to replace"

if [ ${#SECRET_MAP[@]} -eq 0 ]; then
  log_warning "No environment variables found in .env file"
fi

# ------------------------------------------------------------------------
# Helper Function: Check if file should be ignored based on .gitignore
# ------------------------------------------------------------------------
should_ignore_file() {
  local file_path="$1"
  local gitignore_file="$2"
  local base_name
  base_name=$(basename "$file_path")

  # If no .gitignore exists, don't ignore anything
  [ ! -f "$gitignore_file" ] && return 1

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
    if [[ "$base_name" == "$pattern" ]]; then
      return 0
    fi

    # Check for directory patterns (ending with /)
    if [[ "$pattern" == */ ]]; then
      local dir_pattern="${pattern%/}"
      if [[ "$file_path" == "$dir_pattern"* ]] || [[ "$file_path" == *"/$dir_pattern"* ]]; then
        return 0
      fi
    fi

    # Check if pattern matches the relative path
    if [[ "$file_path" == "$pattern" ]] || [[ "$file_path" == *"/""$pattern" ]]; then
      return 0
    fi
  done < "$gitignore_file"

  return 1
}

# ------------------------------------------------------------------------
# Capture Each Dotfile Back
# ------------------------------------------------------------------------
log_info "Capturing dotfiles back to source..."
echo ""

CAPTURED_COUNT=0
CHANGED_COUNT=0
UNCHANGED_COUNT=0
MISSING_COUNT=0

# Get dotfiles from manifest
while IFS='|' read -r source target; do
  # Check if source contains glob patterns
  if [[ "$source" == *"*"* ]] || [[ "$source" == *"?"* ]] || [[ "$source" == *"["* ]]; then
    # Glob pattern detected - target must be a directory
    if [[ "$target" != */ ]]; then
      log_error "Glob pattern in source requires target to be a directory (must end with /): $source -> $target"
      exit 1
    fi

    # Process target path
    HOME_DIR=$(yq eval '.config."home-dir"' "$HOST_MANIFEST" 2> /dev/null || echo "\$HOME")
    target="${target/\~/$HOME_DIR}"
    TARGET_BASE="${target#"$HOME_DIR"/}"

    # Get the source base directory
    # For ** patterns, get the directory before the **
    if [[ "$source" == *"**"* ]]; then
      # Extract path before the first *
      base_pattern="${source%%\*\**}"
      SOURCE_BASE="$REPO_ROOT${base_pattern%/}"
    else
      SOURCE_BASE="$(dirname "$REPO_ROOT$source")"
    fi

    # Find all generated files matching this pattern
    GENERATED_BASE="$GENERATED_DOTFILES_DIR/$TARGET_BASE"
    # Remove trailing slash to avoid double-slash in pattern matching
    GENERATED_BASE="${GENERATED_BASE%/}"

    if [ ! -d "$GENERATED_BASE" ]; then
      log_warning "  ⊘ Generated directory not found for pattern: $source"
      MISSING_COUNT=$((MISSING_COUNT + 1))
      continue
    fi

    # Determine which app this belongs to by finding the app name from the source path
    # Extract app name from source path (e.g., /apps/zsh/dotfiles/** -> zsh)
    APP_NAME=""
    if [[ "$source" =~ /apps/([^/]+)/dotfiles/ ]]; then
      APP_NAME="${BASH_REMATCH[1]}"
    fi

    # Find the .gitignore file for this app
    GITIGNORE_FILE=""
    if [ -n "$APP_NAME" ]; then
      GITIGNORE_FILE="$REPO_ROOT/apps/$APP_NAME/dotfiles/.gitignore"
    fi

    # Find all files in the generated directory (recursively)
    while read -r GENERATED_PATH; do
      # Calculate relative path from generated base
      RELATIVE_TO_BASE="${GENERATED_PATH#"$GENERATED_BASE"/}"

      # Check if file should be ignored
      if should_ignore_file "$RELATIVE_TO_BASE" "$GITIGNORE_FILE"; then
        continue
      fi

      # Construct source path
      SOURCE_PATH="$SOURCE_BASE/$RELATIVE_TO_BASE"

      # Read generated file
      GENERATED_CONTENT=$(cat "$GENERATED_PATH")

      # Replace secrets with environment variable placeholders
      CAPTURED_CONTENT="$GENERATED_CONTENT"

      # Sort secrets by length (longest first) to avoid partial replacements
      sorted_secrets=$(for key in "${!SECRET_MAP[@]}"; do
        echo "${#key} $key"
      done | sort -rn | cut -d' ' -f2-)

      while IFS= read -r secret_value; do
        [ -z "$secret_value" ] && continue
        placeholder="${SECRET_MAP[$secret_value]}"

        # Escape special characters for sed
        escaped_secret=$(printf '%s\n' "$secret_value" | sed -e 's/[]\/$*.^[]/\\&/g')
        escaped_placeholder=$(printf '%s\n' "$placeholder" | sed -e 's/[\/&]/\\&/g')

        # Use sed with literal string matching (parameter expansion can't handle escaped patterns)
        # shellcheck disable=SC2001
        CAPTURED_CONTENT=$(echo "$CAPTURED_CONTENT" | sed "s/$escaped_secret/$escaped_placeholder/g")
      done <<< "$sorted_secrets"

      # Display source path relative to repo root
      SOURCE_DISPLAY="${SOURCE_PATH#"$REPO_ROOT"}"

      # Check if content has changed from source
      if [ -f "$SOURCE_PATH" ]; then
        if diff -q "$SOURCE_PATH" <(echo "$CAPTURED_CONTENT") > /dev/null 2>&1; then
          log_info "  ✓ No changes: $SOURCE_DISPLAY"
          UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
        else
          CHANGED_COUNT=$((CHANGED_COUNT + 1))
          if [ "$DRY_RUN" = true ]; then
            log_warning "  ~ Would update: $SOURCE_DISPLAY"
            echo ""
            echo "    Diff preview:"
            diff -u --color=always "$SOURCE_PATH" <(echo "$CAPTURED_CONTENT") | sed 's/^/      /' || true
            echo ""
          else
            echo "$CAPTURED_CONTENT" > "$SOURCE_PATH"
            log_success "  ✓ Updated: $SOURCE_DISPLAY"
          fi
        fi
      else
        CHANGED_COUNT=$((CHANGED_COUNT + 1))
        if [ "$DRY_RUN" = true ]; then
          log_warning "  + Would create: $SOURCE_DISPLAY"
          echo ""
          echo "    Preview (first 10 lines):"
          echo "$CAPTURED_CONTENT" | head -n 10 | sed 's/^/      /'
          echo ""
        else
          mkdir -p "$(dirname "$SOURCE_PATH")"
          echo "$CAPTURED_CONTENT" > "$SOURCE_PATH"
          log_success "  + Created: $SOURCE_DISPLAY"
        fi
      fi

      CAPTURED_COUNT=$((CAPTURED_COUNT + 1))
    done < <(find "$GENERATED_BASE" -type f)

    continue
  fi

  # Non-glob, single file processing
  SOURCE_PATH="$REPO_ROOT$source"

  # Process target path - expand ~ to home directory path
  HOME_DIR=$(yq eval '.config."home-dir"' "$HOST_MANIFEST" 2> /dev/null || echo "\$HOME")
  target="${target/\~/$HOME_DIR}"

  # Get the relative path from home for the generated file
  TARGET_RELATIVE="${target#"$HOME_DIR"/}"
  GENERATED_PATH="$GENERATED_DOTFILES_DIR/$TARGET_RELATIVE"

  # Check if generated file exists
  if [ ! -f "$GENERATED_PATH" ]; then
    log_warning "  ⊘ Generated file not found: $source"
    MISSING_COUNT=$((MISSING_COUNT + 1))
    continue
  fi

  # Read generated file
  GENERATED_CONTENT=$(cat "$GENERATED_PATH")

  # Replace secrets with environment variable placeholders
  CAPTURED_CONTENT="$GENERATED_CONTENT"

  # Sort secrets by length (longest first) to avoid partial replacements
  sorted_secrets=$(for key in "${!SECRET_MAP[@]}"; do
    echo "${#key} $key"
  done | sort -rn | cut -d' ' -f2-)

  while IFS= read -r secret_value; do
    [ -z "$secret_value" ] && continue
    placeholder="${SECRET_MAP[$secret_value]}"

    # Escape special characters for sed (escape &, /, \, and newlines)
    # This needs to be done carefully to handle all possible characters
    escaped_secret=$(printf '%s\n' "$secret_value" | sed -e 's/[]\/$*.^[]/\\&/g')
    escaped_placeholder=$(printf '%s\n' "$placeholder" | sed -e 's/[\/&]/\\&/g')

    # Use sed with literal string matching (parameter expansion can't handle escaped patterns)
    # shellcheck disable=SC2001
    CAPTURED_CONTENT=$(echo "$CAPTURED_CONTENT" | sed "s/$escaped_secret/$escaped_placeholder/g")
  done <<< "$sorted_secrets"

  # Check if content has changed from source
  if [ -f "$SOURCE_PATH" ]; then
    if diff -q "$SOURCE_PATH" <(echo "$CAPTURED_CONTENT") > /dev/null 2>&1; then
      log_info "  ✓ No changes: $source"
      UNCHANGED_COUNT=$((UNCHANGED_COUNT + 1))
    else
      CHANGED_COUNT=$((CHANGED_COUNT + 1))
      if [ "$DRY_RUN" = true ]; then
        log_warning "  ~ Would update: $source"
        echo ""
        echo "    Diff preview:"
        diff -u --color=always "$SOURCE_PATH" <(echo "$CAPTURED_CONTENT") | sed 's/^/      /' || true
        echo ""
      else
        echo "$CAPTURED_CONTENT" > "$SOURCE_PATH"
        log_success "  ✓ Updated: $source"
      fi
    fi
  else
    CHANGED_COUNT=$((CHANGED_COUNT + 1))
    if [ "$DRY_RUN" = true ]; then
      log_warning "  + Would create: $source"
      echo ""
      echo "    Preview (first 10 lines):"
      echo "$CAPTURED_CONTENT" | head -n 10 | sed 's/^/      /'
      echo ""
    else
      mkdir -p "$(dirname "$SOURCE_PATH")"
      echo "$CAPTURED_CONTENT" > "$SOURCE_PATH"
      log_success "  + Created: $source"
    fi
  fi

  CAPTURED_COUNT=$((CAPTURED_COUNT + 1))
done < <(yq eval '.apps[] | select(.dotfiles != null) | .dotfiles[] | .source + "|" + .target' "$HOST_MANIFEST" 2> /dev/null)

# ------------------------------------------------------------------------
# Final Summary
# ------------------------------------------------------------------------
echo ""
log_info "Summary:"
log_info "  • Total dotfiles processed: $CAPTURED_COUNT"
log_info "  • Changed: $CHANGED_COUNT"
log_info "  • Unchanged: $UNCHANGED_COUNT"
if [ $MISSING_COUNT -gt 0 ]; then
  log_info "  • Missing (not generated): $MISSING_COUNT"
fi
echo ""

if [ "$DRY_RUN" = true ]; then
  log_warning "This was a dry run. No files were modified."
  log_info "Run without --dry-run to apply changes:"
  log_info "  mise run dotfiles:capture"
else
  if [ $CHANGED_COUNT -gt 0 ]; then
    log_success "Successfully captured $CHANGED_COUNT dotfile(s) back to source"
    echo ""
    log_info "Next steps:"
    log_info "1. Review changes: git diff"
    log_info "2. Test that files still work: mise run dotfiles:generate"
    log_info "3. Commit changes: git add . && git commit -m 'feat: update dotfiles'"
  else
    log_success "All dotfiles are already up to date"
  fi
fi

script_footer "success"
