# 5. Keep some activation steps imperative

Status: accepted

## Context

nix-darwin has declarative options for the Dock
(`system.defaults.dock.persistent-apps`), the login shell
(`users.users.<name>.shell` with `users.knownUsers`) and 1Password
(`programs._1password-gui`). This repo does those jobs with activation
scripts under `hosts/<host>/scripts/`.

## Decision

Keep the scripts.

- The Dock includes apps no module installs, which
  `persistent-apps` would either drop or force the repo to start managing.
- Declaring the primary user in `knownUsers` hands its account to
  nix-darwin, a larger change than setting a shell.
- `programs._1password-gui` can move the app bundle, and SSH commit signing
  depends on `/Applications/1Password.app/Contents/MacOS/op-ssh-sign`.

## Consequences

- The scripts are idempotent and skip work that is already done: the Dock is
  only rewritten when it differs, and yazi plugins only reinstall when
  `package.toml` changes.
- Revisit when the Dock list only contains managed apps.
