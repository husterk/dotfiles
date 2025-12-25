# config.nu
#
# Installed by:
# version = "0.102.0"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# This file is loaded after env.nu and before login.nu
#
# You can open this file in your default editor using:
# config nu
#
# See `help config nu` for more options
#
# You can remove these comments if you want or leave
# them for future reference.

# Set VSCode as the preferred Nushell config file editor.
$env.config.buffer_editor = "code"

# $PATH was manually copied from the ZSH $PATH values prior to moving to NuShell.
# Note: These should have been picked up automatically, but they weren't for some unknown reason.
$env.path = ['~/.orbstack/bin']
$env.path ++= ['/Applications/iTerm.app/Contents/Resources/utilities']
$env.path ++= ['/Library/Apple/usr/bin']
$env.path ++= ['/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin']
$env.path ++= ['/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin']
$env.path ++= ['/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin']
$env.path ++= ['/System/Cryptexes/App/usr/bin']
$env.path ++= ['/usr/local/bin']
$env.path ++= ['/opt/homebrew/sbin']
$env.path ++= ['/opt/homebrew/bin']
$env.path ++= ['/usr/bin']
$env.path ++= ['/bin']
$env.path ++= ['/usr/sbin']
$env.path ++= ['/sbin']

# Add Nix to PATH using the standard library helper
use std/util "path add"
path add "/run/current-system/sw/bin"
path add "/nix/var/nix/profiles/default/bin"
# Set NIX_PATH
$env.NIX_PATH = $"darwin-config=($env.HOME)/.nixpkgs/darwin-configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
# Enable SSL certificates for Nix
$env.NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
# Sync the Nix-managed variables
$env.DOCKER_CONFIG = $"($env.HOME)/.config/docker"
$env.WGETRC = $"($env.HOME)/.config/wgetrc"

# 1Password SSH Agent configuration
let onepassword_ssh_sock = $"($env.HOME)/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if ($onepassword_ssh_sock | path exists) {
    $env.SSH_AUTH_SOCK = $onepassword_ssh_sock
}

# ---------------------------------------------------------------
# TODO - Add reusable functions here (example below).
# ---------------------------------------------------------------
