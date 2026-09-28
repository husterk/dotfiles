# 4. One root flake and tracked, non-secret host values

Status: accepted

## Context

Each host used to have its own flake, and its `configuration.nix` was
generated from a template with values pulled from 1Password. Those values
were a name, an email, a username and two paths, none of them secret. The
generated file had to be gitignored and then force-staged so the flake could
see it, CI could not evaluate the system, and a fresh machine could not
bootstrap without the vault.

## Decision

- One root `flake.nix` exposes `darwinConfigurations.<host>` for every
  directory under `hosts/`, sharing one `flake.lock`.
- Each host has a tracked, hand-written `configuration.nix` that reads
  `host-vars.toml` and `host-manifest.toml` with `builtins.fromTOML`, so there
  is no code generation. TOML replaced YAML because Nix parses TOML natively.
- 1Password is reserved for real secrets. There are none today.

## Consequences

- CI builds every host on macOS. Before the switch, a script compared the
  evaluated configuration with the old design and found it identical.
- The public repo shows these values. They were already public in commit
  metadata.

## Alternatives considered

- **sops-nix or agenix.** Worth it once there are real secrets; overhead
  without them.
