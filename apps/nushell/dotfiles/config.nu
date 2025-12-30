# config.nu
# Loaded after env.nu

# Set VSCode as the preferred editor.
$env.config.buffer_editor = "code"

# Use the Standard Library helper to safely manage paths.
use std/util "path add"

# -------------------------------------------------------------------------
# Add your custom paths
# -------------------------------------------------------------------------
path add "~/.orbstack/bin"

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

# This y shell wrapper that provides the ability to change the current working directory
# when exiting Yazi.
def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	^yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# This is the Nushell way to initialize Starship, using the cached
# init script if it is available.
let starship_init_cache = $"($env.HOME)/.cache/starship/init.nu"
if ($starship_init_cache | path exists) {
  source-env ~/.cache/starship/init.nu
}
