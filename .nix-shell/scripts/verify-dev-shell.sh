#!/usr/bin/env bash

# ========================================================================
# Verify Development Shell Setup
# ========================================================================
# This script verifies that the development shell is properly configured
# ========================================================================

set -e

# Source shared helper functions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/../../scripts/script-helpers.sh"

script_header "Development Shell Verification" "Checking Nix development environment configuration"

ERRORS=0

# ------------------------------------------------------------------------
# Check for new files
# ------------------------------------------------------------------------
log_info "Checking for new configuration files..."

# Get to repo root if we're in scripts directory
if [ "$(basename "$PWD")" = "scripts" ]; then
  cd ../..
elif [ "$(basename "$PWD")" = ".nix-shell" ]; then
  cd ..
fi

REPO_ROOT="$PWD"

if [ -f "$REPO_ROOT/.nix-shell/flake.nix" ]; then
  log_success ".nix-shell/flake.nix exists"
else
  log_error ".nix-shell/flake.nix is missing"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$REPO_ROOT/.envrc" ]; then
  log_success ".envrc exists"
else
  log_error ".envrc is missing"
  ERRORS=$((ERRORS + 1))
fi

if [ -f "$REPO_ROOT/.nix-shell/scripts/init-dev-shell.sh" ]; then
  log_success ".nix-shell/scripts/init-dev-shell.sh exists"
else
  log_error ".nix-shell/scripts/init-dev-shell.sh is missing"
  ERRORS=$((ERRORS + 1))
fi

echo ""

# ------------------------------------------------------------------------
# Check .gitignore
# ------------------------------------------------------------------------
log_info "Checking .gitignore updates..."

if grep -q ".direnv/" .gitignore; then
  log_success ".gitignore includes direnv patterns"
else
  log_warning ".gitignore missing direnv patterns"
fi

echo ""

# ------------------------------------------------------------------------
# Check README updates
# ------------------------------------------------------------------------
log_info "Checking README.md updates..."

if grep -q "nix develop" README.md; then
  log_success "README.md mentions nix develop"
else
  log_warning "README.md doesn't mention nix develop"
fi

if grep -q "direnv" README.md; then
  log_success "README.md mentions direnv"
else
  log_warning "README.md doesn't mention direnv"
fi

echo ""

# ------------------------------------------------------------------------
# Check Nix installation
# ------------------------------------------------------------------------
log_info "Checking prerequisites..."

if command -v nix &> /dev/null; then
  log_success "Nix is installed: $(nix --version | head -n1)"
else
  log_warning "Nix is not installed (will be needed to use the dev shell)"
fi

if command -v direnv &> /dev/null; then
  log_success "direnv is installed: $(direnv version)"
else
  log_warning "direnv is not installed (recommended for auto-loading)"
fi

echo ""

# ------------------------------------------------------------------------
# Test flake syntax
# ------------------------------------------------------------------------
if command -v nix &> /dev/null; then
  log_info "Testing flake syntax..."

  if nix flake show "$REPO_ROOT/.nix-shell" --quiet &> /dev/null; then
    log_success "flake.nix syntax is valid"
  else
    log_error "flake.nix has syntax errors"
    ERRORS=$((ERRORS + 1))
  fi

  # Check if devShells.default exists
  if nix flake show "$REPO_ROOT/.nix-shell" 2> /dev/null | grep -q "devShells"; then
    log_success "flake.nix defines devShells"
  else
    log_error "flake.nix missing devShells definition"
    ERRORS=$((ERRORS + 1))
  fi
else
  log_warning "Skipping flake syntax check (Nix not installed)"
fi

echo ""

# ------------------------------------------------------------------------
# Check old devcontainer
# ------------------------------------------------------------------------
log_info "Checking for old files..."

if [ -d ".devcontainer" ]; then
  log_warning ".devcontainer directory still exists (can be removed after testing)"
else
  log_success ".devcontainer directory has been removed"
fi

if [ -d ".vscode" ]; then
  log_warning ".vscode directory still exists (removed for Neovim-only setup)"
else
  log_success ".vscode directory has been removed"
fi

echo ""

# ------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "Next steps:"
  echo "  1. Run: ./scripts/init-dev-shell.sh"
  echo "  2. Restart your shell: source ~/.config/zsh/.zshrc"
  echo "  3. Test the environment: task --list"
  echo "  4. Open Neovim: nvim"
  echo ""
  script_footer "success" "All checks passed! Development shell is properly configured."
else
  script_footer "error" "Found $ERRORS error(s). Please review the issues above."
  exit 1
fi
