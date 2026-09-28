# 2. Use mise for repo tooling alongside Nix

Status: accepted

## Context

Nix builds the system. The repo also needs pinned developer tools (shellcheck,
shfmt, prettier, yq, bats, ruff) and a task runner, on macOS and on Linux CI
runners, with fast updates from Renovate.

## Decision

mise pins repo tools in `mise.toml`, locks checksums for every platform in
`mise.lock`, and runs every workflow as a `mise run` task. Nix provides the
system packages, plus the few tools that must match the flake's nixpkgs
revision exactly (nixfmt, statix, treefmt, deadnix).

## Consequences

- CI installs tools with `mise install --locked` in seconds and verifies the
  checksums, and Renovate updates pins and the lock together.
- A tool can exist in both managers at different versions.
  `dev:check-tool-sync` fails when a dual-managed tool drifts.

## Alternatives considered

- **Nix devShell for everything.** One manager, but slower CI and a heavier
  path for Renovate-driven updates.
