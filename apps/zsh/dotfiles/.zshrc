# ---------------------------------------------------------------
# TODO - UPDATE THIS DOC TO BE OS AGNOSTIC BY USING NIX CONFIGS
#. - This file is currently using the macOS bootstrap as an example.
# ---------------------------------------------------------------

# Configure the ZSH history settings.
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY      # Append to history file rather than replace
setopt SHARE_HISTORY       # Share history between different sessions
setopt HIST_IGNORE_DUPS    # Don't record transitions that are duplicates

# Load compinit and point the dump file to the cache.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Set the Cache directory (XDG Standard).
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR"

# OMZ Settings.
ZSH_THEME="robbyrussell"
plugins=(git sudo docker)

# Explicitly set the path to the Nix-managed OMZ (ZSH=...).
# Note: This is handled in the zsh.nix file.

# Load OMZ.
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "Oh My Zsh not found at $ZSH"
fi

# Load iTerm2 shell integration if available.
# -------------------------------------------
# It enables features like "click to move cursor," status bar indicators, and the ability for iTerm2
# to know your current directory or user for its internal utilities.
if [[ -f "$ZDOTDIR/.iterm2_shell_integration.zsh" ]]; then
    source "$ZDOTDIR/.iterm2_shell_integration.zsh"
else
    echo "iTerm2 shell integration not found at $ZDOTDIR/.iterm2_shell_integration.zsh"
fi
