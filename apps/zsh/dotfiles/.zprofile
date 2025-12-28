# ---------------------------------------------------------------
# TODO - UPDATE THIS DOC TO BE OS AGNOSTIC BY USING NIX CONFIGS
#. - This file is currently using the macOS bootstrap as an example.
# ---------------------------------------------------------------

# Keep Homebrew for other tools that are not managed by Nix, but put it
# at the END of the PATH. This ensures Nix always wins if there is a conflict.
export PATH="$PATH:/opt/homebrew/bin"

# Added by OrbStack: command-line tools and integration
# Comment this line if you don't want it to be added again.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
