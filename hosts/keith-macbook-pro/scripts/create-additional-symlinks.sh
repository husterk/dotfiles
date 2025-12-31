#!/usr/bin/env bash

# ========================================================================
# Create Additional Symlinks
# ========================================================================
# This script creates symlinks for tools managed by nix-darwin that
# need to be accessible in standard system locations.
#
# Current symlinks:
# - 1Password CLI (op): /usr/local/bin/op -> /run/current-system/sw/bin/op
#   The 1Password desktop app integration expects op in /usr/local/bin
# - Nushell Config: ~/.config/nushell -> ~/Library/Application Support/nushell
#   macOS Nushell looks in Library/Application Support by default
#
# Usage: create-additional-symlinks.sh [username]
# Example: create-additional-symlinks.sh keithhuster
# ========================================================================

set -e # Exit on error

# ------------------------------------------------------------------------
# Setup Paths & Load Helpers
# ------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load shared script helpers (skip if already sourced by parent)
if ! command -v script_header &>/dev/null; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/script-helpers.sh"
fi

# Display script header
script_header "Create Additional Symlinks" "Links Nix-managed tools to standard locations"

# ------------------------------------------------------------------------
# Determine Username
# ------------------------------------------------------------------------

# If username provided as argument, use that
if [ -n "$1" ]; then
  username="$1"
# If running via sudo, get the real user
elif [ -n "$SUDO_USER" ]; then
  username="$SUDO_USER"
# Otherwise use current user
else
  username="${USER:-$(whoami)}"
fi

# Get user's home directory
user_home=$(eval echo "~${username}")

log_info "Configuring symlinks for user: ${username}"
log_info "Home directory: ${user_home}"
echo ""

# ------------------------------------------------------------------------
# Symlink Definitions
# ------------------------------------------------------------------------
# Format: "description|source_path|target_path|requires_sudo"
# requires_sudo: "true" for system paths, "false" for user paths
# ------------------------------------------------------------------------

declare -a SYMLINKS=(
  "1Password CLI|/run/current-system/sw/bin/op|/usr/local/bin/op|true"
  "Nushell Config|${user_home}/.config/nushell|${user_home}/Library/Application Support/nushell|false"
)

# ------------------------------------------------------------------------
# Generic Symlink Creation Function
# ------------------------------------------------------------------------

create_symlink() {
  local description="${1}"
  local source_path="${2}"
  local target_path="${3}"
  local requires_sudo="${4}"

  log_info "Checking ${description} symlink..."

  # Check if source exists
  if [ ! -e "${source_path}" ]; then
    log_warning "${description} not found at ${source_path}"
    log_info "Ensure it is installed via nix-darwin configuration."
    return 1
  fi

  # Check if target already exists and is correct
  if [ -L "${target_path}" ]; then
    current_target=$(readlink "${target_path}")
    if [ "${current_target}" = "${source_path}" ]; then
      log_success "${description} symlink already exists and is correct."
      return 0
    else
      log_warning "Symlink exists but points to: ${current_target}"
      log_info "Removing incorrect symlink..."
      if [ "${requires_sudo}" = "true" ]; then
        sudo rm "${target_path}"
      else
        rm "${target_path}"
      fi
    fi
  elif [ -e "${target_path}" ]; then
    log_warning "File/directory exists at ${target_path}"
    log_info "Backing up existing item..."
    backup_path="${target_path}.backup.$(date +%Y%m%d-%H%M%S)"
    if [ "${requires_sudo}" = "true" ]; then
      sudo mv "${target_path}" "${backup_path}"
    else
      mv "${target_path}" "${backup_path}"
    fi
    log_success "Backed up to: ${backup_path}"
  fi

  # Create target directory if needed
  target_dir=$(dirname "${target_path}")
  if [ ! -d "${target_dir}" ]; then
    log_info "Creating directory ${target_dir}..."
    if [ "${requires_sudo}" = "true" ]; then
      sudo mkdir -p "${target_dir}"
    else
      mkdir -p "${target_dir}"
    fi
  fi

  # Create symlink
  log_info "Creating ${description} symlink..."
  if [ "${requires_sudo}" = "true" ]; then
    if sudo ln -sf "${source_path}" "${target_path}"; then
      log_success "Symlink created: ${target_path} -> ${source_path}"
      return 0
    fi
  else
    if ln -sf "${source_path}" "${target_path}"; then
      log_success "Symlink created: ${target_path} -> ${source_path}"
      return 0
    fi
  fi

  log_error "Failed to create symlink."
  return 1
}

# ------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------

log_info "=========================================="
log_info "Creating Additional System Symlinks"
log_info "=========================================="
echo ""

failed=0
total=${#SYMLINKS[@]}

# Process all defined symlinks
for symlink_def in "${SYMLINKS[@]}"; do
  IFS='|' read -r description source_path target_path requires_sudo <<<"${symlink_def}"
  if ! create_symlink "${description}" "${source_path}" "${target_path}" "${requires_sudo}"; then
    failed=$((failed + 1))
  fi
  echo ""
done

log_info "Processed ${total} symlink(s): $((total - failed)) successful, ${failed} failed."
if [ ${failed} -eq 0 ]; then
  script_footer "success"
else
  script_footer "warning" "${failed} symlink(s) failed to configure"
  exit 1
fi
