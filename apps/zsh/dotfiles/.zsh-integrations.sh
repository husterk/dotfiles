# shellcheck shell=bash
# Shell integrations for zsh
# This file is sourced by .zshrc if it exists

# Yazi shell wrapper for changing directory when exiting
if command -v yazi &> /dev/null; then
  function y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd" || return
    rm -f -- "$tmp"
  }
fi

# Initialize zoxide for enhanced directory navigation
# and set the command to use 'cd' for changing directories.
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

# Enable Starship for a fully customizable terminal prompt.
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Hook mise into the shell (replaces direnv)
if command -v mise &> /dev/null; then
  eval "$(mise activate zsh)"
fi

# OrbStack command-line tools and integration
if [ -f "$HOME/.orbstack/shell/init.zsh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.orbstack/shell/init.zsh"
fi
