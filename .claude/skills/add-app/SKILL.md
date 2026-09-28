---
name: add-app
description: Add a new application to this dotfiles repo. Use when the user asks to "add", "install", or "manage" a macOS app/tool/package in this Nix-darwin + mise repo. Scaffolds apps/<name>/<name>.nix, optional dotfiles, and registers the app in hosts/<hostname>/host-manifest.toml. Does NOT run `mise run refresh`; the user does that.
allowed-tools: Read, Write, Edit, Bash, WebSearch, AskUserQuestion
---

# add-app

Scaffold a new application in this dotfiles repo and register it in the host manifest. Stop after files are written. Never run `mise run refresh` yourself.

## When to use

User says any of: "add `<app>`", "install `<app>`", "manage `<app>` with nix/brew", "scaffold an app entry for `<app>`".

If unsure whether they want this skill vs. just editing one file, ask.

## Inputs to gather

If the user did not already specify, use `AskUserQuestion` to collect:

1. **App name**: kebab-case, matches the package name (`ripgrep`, `lazygit`, `agent-of-empires`).
2. **Package source**, one of:
    - `nixpkgs`: preferred for CLI tools available in nixpkgs.
    - `homebrew brew`: for CLI tools not in nixpkgs (e.g. `aoe`).
    - `homebrew cask`: for GUI apps (e.g. `claude`, `davinci-resolve`).
3. **Dotfiles?** yes/no. If yes, ask where the config lives (typical: `~/.config/<name>/`).

Frame the choice in the question; do not pick silently.

## Steps

### 1. Validate

- Read `hosts/<host>/host-manifest.toml` and confirm no existing `[[apps]]` entry has `name = "<name>"`.
- Confirm `apps/<name>/` does not already exist (`ls apps/<name>` should fail).

If either check fails, stop and tell the user. Do not overwrite.

### 2. Write `apps/<name>/<name>.nix`

Pick the template matching the chosen source.

**nixpkgs:**

```nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    <name>
  ];
}
```

**homebrew brew:**

```nix
{ config, pkgs, ... }:

{
  homebrew = {
    brews = [
      "<name>"
    ];
  };
}
```

**homebrew cask:**

```nix
{ config, pkgs, ... }:

{
  homebrew = {
    casks = [
      "<name>"
    ];
  };
}
```

If the package name in the registry differs from the app name (for example, nixpkgs packages ripgrep as `ripgrep` but the binary is `rg`), use the registry name in the list and tell the user.

### 3. (Optional) Scaffold dotfiles

Only when the user requested dotfiles.

1. **WebSearch** for recommended/default config, e.g. `"<app> default config example"`, `"<app> dotfiles config.toml"`. Pull from official docs or well-known dotfiles repos.
2. **Summarize** the recommended config: the file name(s), target path (`~/.config/<name>/...`), and the proposed contents (show the user, do not just write).
3. **Confirm with `AskUserQuestion`**:
    - Accept the recommended config as-is
    - Modify (user provides additions/changes inline)
    - Skip dotfiles (write only the `.nix` module)
4. Write the files under `apps/<name>/dotfiles/`. Mirror the in-config directory layout (so a glob deploy lands files in the right place).
5. **Host values**: if the config needs a per-host value (user name, email), replace it with a `${VAR_NAME}` placeholder and add `VAR_NAME = "<value>"` to `hosts/<host>/host-vars.toml`. That file is public. If the config needs a real secret (API key, token), stop and ask the user; do not write it anywhere in this repo.

### 4. Register in `hosts/<host>/host-manifest.toml`

Insert a new `[[apps]]` block, keeping rough alphabetical order (the existing manifest is mostly alphabetical, so find the right slot rather than reordering the whole file).

Edit the file as text. Do not rewrite it with `yq -i`, which drops the blank lines between blocks. Keys inside a block are alphabetical because taplo runs with `reorder_keys`.

**Without dotfiles:**

```toml
[[apps]]
modules = ["/apps/<name>/<name>.nix"]
name = "<name>"
```

**With dotfiles** (glob form, which matches the dominant style in the manifest):

```toml
[[apps]]
modules = ["/apps/<name>/<name>.nix"]
name = "<name>"
[[apps.dotfiles]]
source = "/apps/<name>/dotfiles/**/*"
target = "~/.config/<name>/"
```

Critical: glob targets **must end with `/`**. Use explicit per-file mapping only when files deploy to different destinations (see the `zsh` entry for an example).

### 5. Report and stop

Print exactly:

```
Created:
  apps/<name>/<name>.nix
  apps/<name>/dotfiles/...   (if applicable)
Registered in hosts/<host>/host-manifest.toml.

Next (run yourself):
  mise run dev:validate-host-config
  mise run refresh
```

**Do not** run `mise run refresh`. The user reviews the diff first.

## Notes

- Homebrew is `cleanup = "zap"` in this repo, so anything not declared in a Nix module gets uninstalled on apply. Adding an app here is the only correct way to keep it.
- Never edit `hosts/<host>/generated/`. It's gitignored and regenerated.
- `<host>` is the output of `hostname -s`, unless the user names another host.
- Templates here use 2-space indent (per `treefmt.toml` / `.editorconfig`); `mise run check` fails on unformatted output, so produce clean output.
