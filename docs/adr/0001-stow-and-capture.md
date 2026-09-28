# 1. Deploy dotfiles with Stow and capture edits back

Status: accepted

## Context

Dotfiles need per-host values (name, email, paths) and need to land in
`$HOME`. The common Nix answer is home-manager, which renders each file into
the read-only Nix store and links it into place.

I edit configuration by trying things in the live file: change
`~/.config/wezterm/wezterm.lua`, see the result, keep going. With read-only
store links, every experiment is an edit to the Nix source plus a rebuild.

## Decision

Templates live in `apps/<name>/dotfiles/` with `${VAR}` placeholders.
`dotfiles:generate` renders them into `hosts/<host>/generated/dotfiles/`,
and GNU Stow links that tree into `$HOME` with `--no-folding`. The links point
at ordinary writable files, so editing `~/.config/...` edits the rendered
copy, and `dotfiles:capture` turns the edits back into templates by
restoring the placeholders the template uses.

## Consequences

- Machine-first editing works, and a bats round-trip test keeps capture
  honest.
- Rendered files are not in the Nix store, so the system closure does not
  pin them; `dotfiles:status` and `dotfiles:diff` show drift instead.
- Deploy prunes links whose source left the repo, since Stow cannot.

## Alternatives considered

- **home-manager.** Better reproducibility and one tool for everything, at
  the cost of the edit-and-see loop above.
- **chezmoi.** Similar capture model, but a second templating system beside
  Nix and mise.
