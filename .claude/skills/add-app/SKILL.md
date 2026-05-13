---
name: add-app
description: Add a new application to this dotfiles repo. Use when the user asks to "add", "install", or "manage" a macOS app/tool/package in this Nix-darwin + mise repo. Scaffolds apps/<name>/<name>.nix, optional dotfiles, and registers the app in hosts/<hostname>/host-manifest.yml. Does NOT run `mise run refresh` — the user does that.
allowed-tools: Read, Write, Edit, Bash, WebSearch, AskUserQuestion
---

# add-app

Scaffold a new application in this dotfiles repo and register it in the host manifest. Stop after files are written — never run `mise run refresh` yourself.

## When to use

User says any of: "add `<app>`", "install `<app>`", "manage `<app>` with nix/brew", "scaffold an app entry for `<app>`".

If unsure whether they want this skill vs. just editing one file, ask.

## Inputs to gather

If the user did not already specify, use `AskUserQuestion` to collect:

1. **App name** — kebab-case, matches the package name (`ripgrep`, `lazygit`, `agent-of-empires`).
2. **Package source** — one of:
    - `nixpkgs` — preferred for CLI tools available in nixpkgs.
    - `homebrew brew` — for CLI tools not in nixpkgs (e.g. `aoe`).
    - `homebrew cask` — for GUI apps (e.g. `claude`, `davinci-resolve`).
3. **Dotfiles?** — yes/no. If yes, ask where the config lives (typical: `~/.config/<name>/`).

Frame the choice in the question; do not pick silently.

## Steps

### 1. Validate

- Read `hosts/keith-macbook-pro/host-manifest.yml` and confirm no existing entry has `name: <name>`.
- Confirm `apps/<name>/` does not already exist (`ls apps/<name>` should fail).

If either check fails, stop and tell the user — do not overwrite.

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

If the package name in the registry differs from the app name (e.g. nixpkgs uses `lazygit` but the binary is `lazygit`), use the registry name in the list and tell the user.

### 3. (Optional) Scaffold dotfiles

Only when the user requested dotfiles.

1. **WebSearch** for recommended/default config — e.g. `"<app> default config example"`, `"<app> dotfiles config.toml"`. Pull from official docs or well-known dotfiles repos.
2. **Summarize** the recommended config: the file name(s), target path (`~/.config/<name>/...`), and the proposed contents (show the user, do not just write).
3. **Confirm with `AskUserQuestion`**:
    - Accept the recommended config as-is
    - Modify (user provides additions/changes inline)
    - Skip dotfiles (write only the `.nix` module)
4. Write the files under `apps/<name>/dotfiles/`. Mirror the in-config directory layout (so a glob deploy lands files in the right place).
5. **Secrets reminder** — if the config will contain secrets (API keys, emails, tokens), replace them with `${VAR_NAME}` placeholders and tell the user to add the var to `hosts/keith-macbook-pro/template.env` (1Password reference). Do not write real secrets.

### 4. Register in `hosts/keith-macbook-pro/host-manifest.yml`

Insert the new app block under `apps:`, keeping rough alphabetical order (the existing manifest is mostly alphabetical — find the right slot, don't reorder the whole file).

**Without dotfiles:**

```yaml
- name: <name>
  modules:
      - /apps/<name>/<name>.nix
```

**With dotfiles** (glob form — matches the dominant style in the manifest):

```yaml
- name: <name>
  modules:
      - /apps/<name>/<name>.nix
  dotfiles:
      - source: /apps/<name>/dotfiles/**/*
        target: ~/.config/<name>/
```

Critical: glob targets **must end with `/`**. Use explicit per-file mapping only when files deploy to different destinations (see the `zsh` entry for an example).

### 5. Report and stop

Print exactly:

```
Created:
  apps/<name>/<name>.nix
  apps/<name>/dotfiles/...   (if applicable)
Registered in hosts/keith-macbook-pro/host-manifest.yml.

Next (run yourself):
  mise run dev:validate-host-config
  mise run refresh
```

**Do not** run `mise run refresh`. The user reviews the diff first.

## Notes

- Homebrew is `cleanup = "zap"` in this repo — anything not declared in a Nix module gets uninstalled on apply. Adding an app here is the only correct way to keep it.
- Never edit `hosts/keith-macbook-pro/generated/` — it's gitignored and regenerated.
- If the user is on a host other than `keith-macbook-pro`, edit the manifest at `hosts/<that-host>/host-manifest.yml`. Use `hostname -s` to detect.
- Templates here use 2-space indent (per `treefmt.toml` / `.editorconfig`); pre-commit will format on commit, but produce clean output anyway.
