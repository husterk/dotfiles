# CLAUDE.md

Agent guide for this repo. See [README.md](README.md) for setup and the full
task list.

This is a declarative macOS config: one root flake builds a nix-darwin system
per host, Stow deploys dotfiles rendered from templates, and mise tasks
orchestrate both.

## Rules

- **Run everything via `mise run <task>`.** Never invoke `tasks/scripts/*.sh`
  or `bootstrap-scripts/**/*.sh` directly. `mise tasks` lists them.
- **Never edit `hosts/<hostname>/generated/`.** Gitignored and
  machine-generated. Regenerate with `mise run dotfiles:generate`.
- **`hosts/<hostname>/host-manifest.toml` is the source of truth** for which
  apps and modules a host gets. Adding an app means creating `apps/<name>/`
  and adding a manifest entry. Edit the manifest as text; never `yq -i`.
- **Host values live in `hosts/<hostname>/host-vars.toml`.** They are not
  secret. Nix reads them directly, and `mise run env:generate` turns them into
  the `.env` that dotfile templates use.
- **Homebrew is `cleanup = "zap"`.** Declare GUI apps in `homebrew.casks`,
  CLI tools in `homebrew.brews`. Anything not declared in a Nix module gets
  uninstalled on apply.
- **Private casks live in a separate private overlay repo**, cloned at
  `~/git-repos/dotfiles-private` and passed to the flake's `private` input by
  `mise run nix:apply`. Without the overlay, the tracked stub turns zap off
  and the apply script refuses to run. Never write private app names in this
  repo.

## Apps pattern

```
apps/<name>/
  <name>.nix     # nix-darwin module: packages, env vars
  dotfiles/      # optional; ${VAR} templates substituted at generation
```

Template vars come from `hosts/<hostname>/host-vars.toml`.

## Editing dotfiles

- **Machine-first**: edit `~/.config/...`, then `mise run dotfiles:capture`
  (strips secrets back to templates).
- **Code-first**: edit `apps/<name>/dotfiles/...`, then `mise run refresh`
  (regenerates + redeploys).

## Workflow

- **An issue comes first.** Before changing any tracked file, find or create a
  GitHub issue with a goal and checkable acceptance criteria. The `start-work`
  skill walks through it.
- **One branch and one PR per issue.** Name the branch
  `<type>/<issue-number>-<slug>`, and put `Closes #<number>` in the PR body.
  The `Linked issue` CI check fails a PR without an open linked issue.
- **Commit messages never contain `#<number>`.** The PR body carries the link.
- **Verify before merging.** Run each acceptance criterion and post the
  commands and results as a comment on the issue.

## CI job to local command

Every required CI job has a local equivalent:

| Failing job                              | Local command                                                      |
| ---------------------------------------- | ------------------------------------------------------------------ |
| Format and lint / Formatting is clean    | `mise run dev:format-check`                                        |
| Format and lint / Lint                   | `mise run dev:lint`                                                |
| Tool pins and manifests / pins agree     | `mise run dev:check-tool-pins`                                     |
| Tool pins and manifests / host manifests | `mise run dev:validate-all-hosts`                                  |
| Tool pins and manifests / install        | `mise install --locked`                                            |
| Tests                                    | `mise run dev:test`                                                |
| Build nix-darwin systems                 | `nix build --no-link .#darwinConfigurations.$(hostname -s).system` |
| Linked issue                             | Put `Closes #<number>` for an open issue in the PR body            |

## Formatting & lint

Run `mise run check` before every commit. It runs `dev:format-check`,
`dev:lint` and `dev:validate-all-hosts`, the same gates CI enforces.
`mise run dev:format` fixes formatting. There is no pre-commit hook. Fix the
underlying issue rather than skipping a check.
