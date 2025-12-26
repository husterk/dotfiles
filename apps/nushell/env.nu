# env.nu
# Loaded before config.nu

# Define how to convert the PATH string into a Nushell list.
$env.ENV_CONVERSIONS = {
  "PATH": {
    from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
    to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
  }
}

# Ensure the main Nix-Darwin path is present immediately.
$env.PATH = ($env.PATH | split row (char esep) | append '/run/current-system/sw/bin' | uniq)
