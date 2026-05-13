# CLAUDE.md

Agent guide for this repo. See [README.md](README.md) for setup and the full
task list.

This is a declarative macOS config: Nix-darwin packages + Stow-deployed
dotfiles + 1Password secrets, orchestrated by mise tasks.

## Rules

- **Run everything via `mise run <task>`.** Never invoke `tasks/scripts/*.sh`
  or `bootstrap-scripts/**/*.sh` directly. `mise tasks` lists them.
- **Never edit `hosts/<hostname>/generated/`.** Gitignored, machine-generated,
  contains 1Password secrets. Regenerate via `mise run nix:generate` or
  `mise run dotfiles:generate`.
- **`hosts/<hostname>/host-manifest.yml` is the source of truth** for which
  apps/modules a host gets. Adding an app = create `apps/<name>/` + add a
  manifest entry.
- **Homebrew is `cleanup = "zap"`.** Declare GUI apps in `homebrew.casks`,
  CLI tools in `homebrew.brews`. Anything not declared in a Nix module gets
  uninstalled on apply.

## Apps pattern

```
apps/<name>/
  <name>.nix     # nix-darwin module: packages, env vars
  dotfiles/      # optional; ${VAR} templates substituted at generation
```

Template vars come from `hosts/<hostname>/template.env` (1Password refs).
Run `op signin` before any `*:generate` task.

## Editing dotfiles

- **Machine-first**: edit `~/.config/...`, then `mise run dotfiles:capture`
  (strips secrets back to templates).
- **Code-first**: edit `apps/<name>/dotfiles/...`, then `mise run refresh`
  (regenerates + redeploys).

## Formatting & lint

`mise run dev:format` / `mise run dev:lint`. Pre-commit hook runs both — fix
the underlying issue rather than skipping.
