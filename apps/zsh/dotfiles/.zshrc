# Configure the ZSH history settings.
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY      # Append to history file rather than replace
setopt SHARE_HISTORY       # Share history between different sessions
setopt HIST_IGNORE_DUPS    # Don't record transitions that are duplicates

# Load compinit and point the dump file to the cache.
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Activate syntax highlighting
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
(( ${+ZSH_HIGHLIGHT_STYLES} )) || typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none

# Activate autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# This y shell wrapper that provides the ability to change the current working directory when
# exiting Yazi.
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Hook direnv into the shell
eval "$(direnv hook zsh)"

# Enable Starship for a fully customizable terminal prompt.
eval "$(starship init zsh)"
