# integrations.nu
# Shell integrations for Nushell
# This file is sourced by config.nu if it exists

# Yazi shell wrapper for changing directory when exiting
def --env y [...args] {
	let tmp = (mktemp -t "yazi-cwd.XXXXXX")
	^yazi ...$args --cwd-file $tmp
	let cwd = (open $tmp)
	if $cwd != "" and $cwd != $env.PWD {
		cd $cwd
	}
	rm -fp $tmp
}

# Initialize zoxide for enhanced directory navigation
# This will take over the default 'cd' command to use zoxide's functionality.
# env.nu regenerates the init script on every start.
if ("~/.cache/zoxide/init.nu" | path expand | path exists) {
  source "~/.cache/zoxide/init.nu"
}

# Initialize Starship prompt
# Uses the cached init script that was created in env.nu
if ("~/.cache/starship/init.nu" | path expand | path exists) {
  source-env "~/.cache/starship/init.nu"
}

# Hook mise into the shell (replaces direnv)
# This should be at the end to ensure it works correctly.
if ("~/.cache/mise/activate.nu" | path expand | path exists) {
  source-env "~/.cache/mise/activate.nu"
}
