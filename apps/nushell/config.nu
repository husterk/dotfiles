# config.nu
# Loaded after env.nu

# Set VSCode as the preferred editor.
$env.config.buffer_editor = "code"

# Use the Standard Library helper to safely manage paths.
use std/util "path add"

# -------------------------------------------------------------------------
# Add your custom paths WITHOUT overwriting the system path 
# -------------------------------------------------------------------------
path add "~/.orbstack/bin"
path add "/Applications/iTerm.app/Contents/Resources/utilities"
path add "/Library/Apple/usr/bin"
path add "/usr/local/bin"
path add "/opt/homebrew/bin"
path add "/opt/homebrew/sbin"

# -------------------------------------------------------------------------
# Explicitly ensure Nix paths are at the front
# -------------------------------------------------------------------------
path add "/run/current-system/sw/bin"
path add "/nix/var/nix/profiles/default/bin"
path add $"($env.HOME)/.nix-profile/bin"

# Corrected NIX_PATH for your specific dotfiles setup.
$env.NIX_PATH = $"darwin-config=($env.HOME)/dotfiles/darwin-configuration.nix:/nix/var/nix/profiles/per-user/root/channels"

# Enable SSL certificates for Nix.
$env.NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"

# Sync Nix-managed variables.
$env.DOCKER_CONFIG = $"($env.HOME)/.config/docker"
$env.WGETRC = $"($env.HOME)/.config/wgetrc"

# 1Password SSH Agent configuration.
let onepassword_ssh_sock = $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if ($onepassword_ssh_sock | path exists) {
    $env.SSH_AUTH_SOCK = $onepassword_ssh_sock
}
