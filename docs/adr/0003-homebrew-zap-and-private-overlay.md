# 3. Declare every Homebrew package, zap the rest, and keep some private

Status: accepted

## Context

GUI apps on macOS mostly come from Homebrew casks. Without cleanup, anything
installed by hand lingers and the machine drifts from the repo. Some apps on
this machine should not be listed in a public repository.

## Decision

- nix-darwin manages Homebrew with `cleanup = "zap"`, so an undeclared
  package is uninstalled on apply, together with the data its zap stanza
  names.
- `autoUpdate` and `upgrade` stay on: Homebrew packages track their latest
  releases, and Nix remains the pinned side.
- Casks that are not published live in a separate private repository whose
  `default.nix` is a nix-darwin module. The flake's `private` input defaults
  to a tracked stub; `nix:apply` overrides it with the local clone.

## Consequences

- The stub forces `cleanup` to `none`, so any build without the private
  overlay (CI, a fresh machine, a mistaken apply) never zaps anything.
- `nix:apply` refuses to run without the overlay unless
  `ALLOW_PUBLIC_STUB=1` is set, so a missing clone is reported rather than
  silently leaving private casks unmanaged.
- The public flake builds anywhere with no private access.

## Alternatives considered

- **A gitignored file in this repo.** A git-backed flake only sees tracked
  files, so the flake could not read it.
- **Pinning Homebrew with nix-homebrew.** More reproducible taps, more
  machinery; not needed while casks track latest.
