# config.nu
# Loaded after env.nu

# Set VSCode as the preferred editor.
$env.config.buffer_editor = "code"

# Use the Standard Library helper to safely manage paths.
use std/util "path add"

# -------------------------------------------------------------------------
# Add your custom paths (with existence checks)
# -------------------------------------------------------------------------
# OrbStack command-line tools
if ("~/.orbstack/bin" | path expand | path exists) {
    path add "~/.orbstack/bin"
}

# Enable SSL certificates for Nix.
$env.NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"

# Sync Nix-managed variables.
$env.DOCKER_CONFIG = $"($env.HOME)/.config/docker"
$env.WGETRC = $"($env.HOME)/.config/wget/wgetrc"

# 1Password SSH Agent configuration.
let onepassword_ssh_sock = $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if ($onepassword_ssh_sock | path exists) {
    $env.SSH_AUTH_SOCK = $onepassword_ssh_sock
}

# Load shell integrations (starship, mise, zoxide, yazi, etc.)
if ("~/.config/nushell/integrations.nu" | path expand | path exists) {
  source "~/.config/nushell/integrations.nu"
}
