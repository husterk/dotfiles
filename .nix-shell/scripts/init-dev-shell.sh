#!/usr/bin/env bash

# ========================================================================
# Initialize Development Shell
# ========================================================================
# Run this script the first time you work with this repository to set up
# the Nix development environment with direnv auto-loading.
# ========================================================================

set -e

# Source shared helper functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/script-helpers.sh"

script_header "Development Shell Initialization" "Setting up Nix development environment with direnv"

# ------------------------------------------------------------------------
# Determine Repository Root
# ------------------------------------------------------------------------

# Get to repo root if we're in scripts directory
if [ "$(basename "$PWD")" = "scripts" ]; then
  cd ../..
elif [ "$(basename "$PWD")" = ".nix-shell" ]; then
  cd ..
fi

REPO_ROOT="$PWD"
log_info "Repository root: $REPO_ROOT"
echo ""

# ------------------------------------------------------------------------
# Step 1: Verify Prerequisites
# ------------------------------------------------------------------------
log_info "Checking prerequisites..."

if ! command -v nix &> /dev/null; then
  log_error "Nix is not installed. Please bootstrap your host first:"
  echo "  task setup-host"
  exit 1
fi

log_success "Nix is installed"

# Check for direnv
if ! command -v direnv &> /dev/null; then
  log_error "direnv is not installed."
  echo ""
  echo "Please add direnv to your nix-darwin configuration:"
  echo "  1. Edit: hosts/$(hostname -s)/configuration.nix"
  echo "  2. Add 'direnv' to environment.systemPackages"
  echo "  3. Run: darwin-rebuild switch --flake ~/git-repos/dotfiles/hosts/$(hostname -s)"
  echo ""
  echo "Or install temporarily with:"
  echo "  nix profile install nixpkgs#direnv"
  echo ""
  exit 1
fi

log_success "direnv is available"

# ------------------------------------------------------------------------
# Step 2: Check 1Password Authentication
# ------------------------------------------------------------------------
log_info "Checking 1Password authentication..."

if ! op account list &> /dev/null; then
  log_warning "1Password CLI is not authenticated."
  echo ""
  echo "The development shell will auto-generate .env when you authenticate."
  echo "To authenticate now:"
  echo "  eval \$(op signin)"
  echo ""
else
  log_success "1Password CLI is authenticated"

  # Generate .env immediately if template exists
  if [ -f "$REPO_ROOT/.nix-shell/.env.template" ]; then
    if [ ! -f "$REPO_ROOT/.env" ] || [ "$REPO_ROOT/.nix-shell/.env.template" -nt "$REPO_ROOT/.env" ]; then
      log_info "Generating .env file from 1Password secrets..."
      if op inject -i "$REPO_ROOT/.nix-shell/.env.template" -o "$REPO_ROOT/.env" &> /dev/null; then
        log_success "Generated .env file with secrets from 1Password"
      else
        log_warning "Failed to generate .env file (check vault access)"
      fi
    else
      log_success ".env file is up to date"
    fi
  fi
fi

echo ""

# ------------------------------------------------------------------------
# Step 3: Set up direnv
# ------------------------------------------------------------------------
log_info "Configuring direnv..."

# Determine zsh config location (check XDG and standard locations)
ZSHRC_PATH=""
if [ -n "$XDG_CONFIG_HOME" ] && [ -f "$XDG_CONFIG_HOME/zsh/.zshrc" ]; then
  ZSHRC_PATH="$XDG_CONFIG_HOME/zsh/.zshrc"
elif [ -f "$HOME/.config/zsh/.zshrc" ]; then
  ZSHRC_PATH="$HOME/.config/zsh/.zshrc"
elif [ -f "$HOME/.zshrc" ]; then
  ZSHRC_PATH="$HOME/.zshrc"
fi

# Add direnv hook to zsh config if not already present
if [ -n "$ZSHRC_PATH" ]; then
  if ! grep -q "direnv hook zsh" "$ZSHRC_PATH" 2> /dev/null; then
    {
      echo ''
      echo '# direnv integration'
      # shellcheck disable=SC2016
      echo 'eval "$(direnv hook zsh)"'
    } >> "$ZSHRC_PATH"
    log_success "Added direnv hook to $ZSHRC_PATH"
  else
    log_info "direnv hook already in $ZSHRC_PATH"
  fi
else
  log_warning "zsh config not found. Please add this to your shell config:"
  # shellcheck disable=SC2016
  echo '  eval "$(direnv hook zsh)"'
fi

# ------------------------------------------------------------------------
# Step 4: Allow direnv
# ------------------------------------------------------------------------
log_info "Allowing direnv for this directory..."

if [ -f "$REPO_ROOT/.envrc" ]; then
  direnv allow "$REPO_ROOT"
  log_success "direnv allowed for workspace"
else
  log_error ".envrc file not found at $REPO_ROOT/.envrc"
  exit 1
fi

# ------------------------------------------------------------------------
# Step 5: Test Development Shell
# ------------------------------------------------------------------------
log_info "Testing development shell..."

if nix develop "$REPO_ROOT/.nix-shell" --command echo "Nix shell works!" &> /dev/null; then
  log_success "Development shell is working"
else
  log_error "Development shell failed to load"
  log_info "Trying to build flake..."
  nix develop "$REPO_ROOT/.nix-shell" --command echo "Test"
  exit 1
fi

# ------------------------------------------------------------------------
# Completion
# ------------------------------------------------------------------------

echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.config/zsh/.zshrc"
echo "  2. Navigate to this directory - direnv will auto-load the environment"
echo "  3. .env will auto-generate from 1Password when authenticated"
echo "  4. Open Neovim and start coding: nvim"
echo "  5. Run tasks: task --list"
echo ""

script_footer "success"
