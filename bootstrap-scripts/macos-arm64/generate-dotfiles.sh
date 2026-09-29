#!/usr/bin/env bash

# ========================================================================
# macOS ARM Generate Dotfiles Script
# ========================================================================
# This script generates host-specific dotfiles by:
# - Loading environment variables from generated .env file
# - Generating dotfiles hierarchy with variable substitution
# - Creating home-relative paths for GNU Stow compatibility
#
# Prerequisites: generate-env.sh must be run first to create .env
#
# Usage: ./generate-dotfiles.sh [hostname]
# Example: ./generate-dotfiles.sh keith-macbook-pro
# ========================================================================

set -euo pipefail

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Set to regenerate without checking the generated tree for edits made in
# place; any such edit is lost.
FORCE_OVERWRITE="${FORCE_OVERWRITE:-false}"

# Load shared script helpers
# shellcheck disable=SC1091
source "${REPO_ROOT}/scripts/script-helpers.sh"

# Display script header
script_header "Generate Dotfiles" "Creates host-specific dotfiles with variable substitution"

# ------------------------------------------------------------------------
# Step 0: Parse Arguments and Setup Paths
# ------------------------------------------------------------------------
HOSTNAME="${1:-}"

if [ -z "$HOSTNAME" ]; then
  log_error "No hostname provided."
  echo ""
  echo "Usage: $0 <hostname>"
  echo ""
  echo "Example: $0 keith-macbook-pro"
  echo ""

  # Determine the git repo root directory
  REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2> /dev/null || echo "")

  if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/hosts" ]; then
    echo "Available hosts:"
    find "$REPO_ROOT/hosts" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  - /'
  fi

  exit 1
fi

log_info "Generating dotfiles for host: $HOSTNAME"

# Determine the git repo root directory
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2> /dev/null || echo "")

if [ -z "$REPO_ROOT" ]; then
  log_error "This script must be run from within a git repository."
  exit 1
fi

log_info "Repository root: $REPO_ROOT"

# Check if host directory exists
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"

if [ ! -d "$HOST_DIR" ]; then
  log_error "Host directory not found: $HOST_DIR"
  log_info "Available hosts:"
  if [ -d "$REPO_ROOT/hosts" ]; then
    find "$REPO_ROOT/hosts" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sed 's/^/  - /'
  fi
  exit 1
fi

log_success "Found host directory: $HOST_DIR"

# Define key file paths
HOST_MANIFEST="$HOST_DIR/host-manifest.toml"
GENERATED_DIR="$HOST_DIR/generated"
GENERATED_ENV="$GENERATED_DIR/.env"
GENERATED_DOTFILES_DIR="$GENERATED_DIR/dotfiles"
# Checksums of the tree as last generated. An edit made through a Stow link
# lands in the tree, so any difference is work that capture has not saved.
GENERATED_MANIFEST="$GENERATED_DIR/dotfiles.sha256"

# Validate required files exist
if [ ! -f "$HOST_MANIFEST" ]; then
  log_error "Host manifest not found: $HOST_MANIFEST"
  exit 1
fi

if [ ! -f "$GENERATED_ENV" ]; then
  log_error "Generated .env file not found: $GENERATED_ENV"
  log_info "Please run: mise run env:generate"
  exit 1
fi

log_success "All required files found."

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Verifying prerequisites..."

if ! command -v yq &> /dev/null; then
  log_error "yq is required but not installed."
  log_info "Install it with: brew install yq"
  exit 1
fi

log_success "All prerequisites verified."

dotfiles_checksums() {
  (cd "$GENERATED_DOTFILES_DIR" && find . -type f -exec shasum -a 256 {} + | LC_ALL=C sort -k 2)
}

confirm_overwrite() {
  if [ ! -t 0 ]; then
    log_error "No terminal to confirm, so nothing was deleted."
    log_info "Capture the changes with: mise run dotfiles:capture"
    log_info "Or discard them with: FORCE_OVERWRITE=true mise run dotfiles:generate"
    exit 1
  fi
  echo -n "Continue? (y/N): "
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    log_info "Generation cancelled by user."
    exit 0
  fi
}

# ------------------------------------------------------------------------
# Step 2: Clean Generated Dotfiles Directory
# ------------------------------------------------------------------------
if [ -d "$GENERATED_DOTFILES_DIR" ]; then
  if [ "$FORCE_OVERWRITE" = true ]; then
    log_info "Force overwrite enabled, regenerating dotfiles directory..."
  elif [ ! -f "$GENERATED_MANIFEST" ]; then
    log_warning "Generated dotfiles directory already exists: $GENERATED_DOTFILES_DIR"
    log_warning "It has no checksum record, so edits made in place cannot be detected."
    log_warning "All files in this directory will be deleted and regenerated."
    confirm_overwrite
  elif ! changed="$(diff "$GENERATED_MANIFEST" <(dotfiles_checksums))"; then
    log_warning "These files changed since the last generation and would be lost:"
    sed -nE 's/^[<>] [0-9a-f]{64}  \.\///p' <<< "$changed" | LC_ALL=C sort -u | sed 's/^/  - /'
    confirm_overwrite
  else
    log_info "No generated file changed since the last generation."
  fi

  log_info "Removing existing dotfiles..."
  rm -f "$GENERATED_MANIFEST"
  rm -rf "$GENERATED_DOTFILES_DIR"
  log_success "Cleaned dotfiles directory."
fi

# ------------------------------------------------------------------------
# Step 3: Load environment variables from .env
# ------------------------------------------------------------------------
log_info "Loading environment variables from .env..."

# Source the .env file to load variables
if [ -f "$GENERATED_ENV" ]; then
  set -a # automatically export all variables
  # shellcheck source=/dev/null
  source "$GENERATED_ENV"
  set +a
  log_success "Environment variables loaded."

  # Build envsubst variable list (only substitute vars from .env)
  ENVSUBST_VARS=$(grep -v '^#' "$GENERATED_ENV" | grep '=' | cut -d= -f1 | sed 's/^/$/' | tr '\n' ' ')
else
  log_error "Generated .env file not found: $GENERATED_ENV"
  exit 1
fi

# ------------------------------------------------------------------------
# Step 4: Generate dotfiles hierarchy
# ------------------------------------------------------------------------
log_info "Generating dotfiles hierarchy..."

# Create dotfiles directory
mkdir -p "$GENERATED_DOTFILES_DIR"

# Get count of dotfiles entries
DOTFILES_COUNT=$(yq -p toml -o yaml eval '.apps[].dotfiles[]' "$HOST_MANIFEST" 2> /dev/null | grep -c "source:" || true)

if [ "$DOTFILES_COUNT" -eq 0 ]; then
  log_warning "No dotfiles found in manifest."
else
  log_info "Processing $DOTFILES_COUNT dotfiles entries..."

  # Process each dotfile entry
  while IFS='|' read -r source target; do
    # Check if source contains glob patterns
    if [[ "$source" == *"*"* ]] || [[ "$source" == *"?"* ]] || [[ "$source" == *"["* ]]; then
      # Glob pattern detected - target must be a directory
      if [[ "$target" != */ ]]; then
        log_error "Glob pattern in source requires target to be a directory (must end with /): $source -> $target"
        exit 1
      fi

      # Resolve glob pattern
      SOURCE_PATTERN="$REPO_ROOT$source"

      # Find all matching files (using nullglob to handle no matches gracefully)
      # Enable globstar for ** recursive patterns
      shopt -s nullglob dotglob globstar
      # shellcheck disable=SC2206
      MATCHED_FILES=($SOURCE_PATTERN)
      shopt -u nullglob dotglob globstar

      if [ ${#MATCHED_FILES[@]} -eq 0 ]; then
        log_warning "No files matched glob pattern: $source (skipping)"
        continue
      fi

      # Process each matched file
      for SOURCE_PATH in "${MATCHED_FILES[@]}"; do
        # Skip if not a file
        if [ ! -f "$SOURCE_PATH" ]; then
          continue
        fi

        # Skip .gitignore files (used for capture filtering, not deployment)
        if [[ "$(basename "$SOURCE_PATH")" == ".gitignore" ]]; then
          continue
        fi

        # Get the source base directory (directory containing the glob pattern)
        # For ** patterns, extract the directory before **
        if [[ "$source" == *"**"* ]]; then
          # Extract path before the first *
          base_pattern="${source%%\*\**}"
          SOURCE_BASE="$REPO_ROOT${base_pattern%/}"
        else
          SOURCE_BASE="$(dirname "$REPO_ROOT$source")"
        fi

        # Calculate relative path from source base
        RELATIVE_TO_BASE="${SOURCE_PATH#"$SOURCE_BASE"}"
        # Remove leading slash if present
        RELATIVE_TO_BASE="${RELATIVE_TO_BASE#/}"

        # Replace ~ with empty string and expand env vars in target
        target="${target/\~\//}"
        TARGET_PATH=$(echo "$target" | envsubst "$ENVSUBST_VARS")

        # Combine target directory with relative path
        RELATIVE_PATH="$TARGET_PATH$RELATIVE_TO_BASE"
        DEST_PATH="$GENERATED_DOTFILES_DIR/$RELATIVE_PATH"

        # Create destination directory hierarchy
        mkdir -p "$(dirname "$DEST_PATH")"

        # Copy and substitute environment variables
        envsubst "$ENVSUBST_VARS" < "$SOURCE_PATH" > "$DEST_PATH"

        log_info "  ✓ Generated: $RELATIVE_PATH"
      done
    else
      # Non-glob, single file processing
      # Resolve source path (relative to REPO_ROOT)
      SOURCE_PATH="$REPO_ROOT$source"

      # Skip .gitignore files (used for capture filtering, not deployment)
      if [[ "$(basename "$SOURCE_PATH")" == ".gitignore" ]]; then
        continue
      fi

      # Replace ~ with empty string to get home-relative path (for Stow compatibility)
      # Stow expects files to be relative to the target directory (home), not absolute paths
      target="${target/\~\//}"

      # Expand environment variables in target path (only from .env)
      TARGET_PATH=$(echo "$target" | envsubst "$ENVSUBST_VARS")

      # Use the target path directly as relative path (already home-relative)
      RELATIVE_PATH="$TARGET_PATH"

      DEST_PATH="$GENERATED_DOTFILES_DIR/$RELATIVE_PATH"

      # Create destination directory hierarchy
      mkdir -p "$(dirname "$DEST_PATH")"

      # Check if source file exists
      if [ ! -f "$SOURCE_PATH" ]; then
        log_warning "Source file not found: $SOURCE_PATH (skipping)"
        continue
      fi

      # Copy and substitute environment variables (only from .env)
      envsubst "$ENVSUBST_VARS" < "$SOURCE_PATH" > "$DEST_PATH"

      log_info "  ✓ Generated: $RELATIVE_PATH"
    fi
  done < <(yq -p toml -o yaml eval '.apps[] | select(.dotfiles != null) | .dotfiles[] | .source + "|" + .target' "$HOST_MANIFEST")

  log_success "Generated dotfiles in: $GENERATED_DOTFILES_DIR"
fi

dotfiles_checksums > "$GENERATED_MANIFEST"

# ------------------------------------------------------------------------
# Step 5: Final Summary
# ------------------------------------------------------------------------
log_info "Generated files:"
log_info "  • Dotfiles directory: $GENERATED_DOTFILES_DIR"
echo ""

log_info "Next steps:"
log_info "1. Review the generated dotfiles in: $GENERATED_DOTFILES_DIR"
log_info "2. Deploy dotfiles using: ./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $HOSTNAME"
script_footer "success"
