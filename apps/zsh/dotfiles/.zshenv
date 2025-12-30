# Used for environment variables that need to be available even in
# non-interactive scripts.

# Disable macOS-specific terminal session saving (.zsh_sessions).
SHELL_SESSIONS_DISABLE="1"

# Ensure the folder exists immediately so that history can be written.
if [[ ! -d "$ZSH_HISTORY_DIR" ]]; then
    mkdir -p "$ZSH_HISTORY_DIR"
fi

# Custom themes and plugins location.
ZSH_CUSTOM="$ZDOTDIR/custom" # Must be named ZSH_CUSTOM for Zsh.

# Ensure the custom folder exists.
if [[ ! -d "$ZSH_CUSTOM" ]]; then
    mkdir -p "$ZSH_CUSTOM"
fi

# Add Homebrew to PATH
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
