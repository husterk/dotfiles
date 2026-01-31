# Configure the ZSH history settings.
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY   # Append to history file rather than replace
setopt SHARE_HISTORY    # Share history between different sessions
setopt HIST_IGNORE_DUPS # Don't record transitions that are duplicates

# Load compinit and point the dump file to the cache.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Activate syntax highlighting
if command -v brew &> /dev/null; then
  local syntax_highlighting="$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  if [ -f "$syntax_highlighting" ]; then
    source "$syntax_highlighting"
    [[ -v ZSH_HIGHLIGHT_STYLES ]] || typeset -A ZSH_HIGHLIGHT_STYLES
    ZSH_HIGHLIGHT_STYLES[path]=none
    ZSH_HIGHLIGHT_STYLES[path_prefix]=none
  fi
fi

# Activate autosuggestions
if command -v brew &> /dev/null; then
  local autosuggestions="$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  if [ -f "$autosuggestions" ]; then
    source "$autosuggestions"
  fi
fi

# Load shell integrations (starship, mise, zoxide, yazi, etc.)
if [ -f "$ZDOTDIR/.zsh-integrations.sh" ]; then
  source "$ZDOTDIR/.zsh-integrations.sh"
fi
