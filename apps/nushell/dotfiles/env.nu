# env.nu
# Loaded before config.nu
# This file sets up the environment for Nushell, including PATH for Nix-managed packages

# Define how to convert the PATH string into a Nushell list.
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
  }
}

# Set NIX_PROFILES for Nix to find packages
$env.NIX_PROFILES = "/nix/var/nix/profiles/default /run/current-system/sw"

# Build PATH explicitly with all necessary directories
# Start fresh to ensure Nix paths have priority
$env.PATH = [
    '/run/current-system/sw/bin'                    # nix-darwin system packages (highest priority)
    ($env.HOME | path join '.nix-profile' 'bin')    # user nix packages
    '/nix/var/nix/profiles/default/bin'             # default nix profile
    '/usr/local/bin'                                 # homebrew/local tools
    '/usr/bin'                                       # system binaries
    '/bin'                                           # basic system binaries
    '/usr/sbin'                                      # system admin binaries
    '/sbin'                                          # basic system admin binaries
]

# Add Homebrew to Nushell PATH at the END (after Nix)
# This ensures Nix always wins if there is a conflict, consistent with zsh approach
let brew_path = "/opt/homebrew/bin"
if ($brew_path | path exists) {
    $env.PATH = ($env.PATH | append $brew_path)
}

# This is the Nushell way to initialize Starship, creating the cached
# init script if it is not yet available.
let starship_cache = ($env.HOME | path join ".cache" "starship")
let starship_init = ($starship_cache | path join "init.nu")

# Check if directory exists, create if not
if not ($starship_cache | path exists) {
    mkdir $starship_cache
}

# Generate the file if it doesn't exist
if not ($starship_init | path exists) {
    starship init nu | save -f $starship_init
}

# zoxide's init script changes between releases, so regenerate it on every
# start rather than committing a copy that goes stale. --cmd cd makes zoxide
# take over cd.
let zoxide_cache = ($env.HOME | path join ".cache" "zoxide")
if not ($zoxide_cache | path exists) {
    mkdir $zoxide_cache
}
zoxide init nushell --cmd cd | save -f ($zoxide_cache | path join "init.nu")
