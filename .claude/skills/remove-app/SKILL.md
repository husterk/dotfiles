---
name: remove-app
description: Remove an application from this dotfiles repo. Use when the user asks to "remove", "uninstall", "drop", or "delete" a macOS app/tool from the Nix-darwin + mise config. Deletes apps/<name>/ and unregisters it from hosts/<hostname>/host-manifest.toml. Does NOT run `mise run refresh`; the user does that.
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# remove-app

Unregister an app from the host manifest and delete its `apps/<name>/` directory. Stop after files are changed. Never run `mise run refresh` yourself.

## When to use

User says any of: "remove `<app>`", "uninstall `<app>`", "drop `<app>` from the manifest", "delete the `<app>` entry".

## Inputs to gather

1. **App name**: if not specified, list the current apps from `apps/` (`ls apps/`) and `AskUserQuestion` for the right one.

## Steps

### 1. Validate

- Confirm `apps/<name>/` exists.
- Confirm an `[[apps]]` entry with `name = "<name>"` exists in `hosts/<host>/host-manifest.toml`.

If only one of those is true, surface the inconsistency and ask the user whether to proceed (likely yes, since the repo is partially out of sync).

### 2. Scan for cross-references

Run:

```bash
git grep -n -e "<name>" -- hosts/ modules/ apps/ ':!apps/<name>/'
```

This surfaces unrelated mentions (other apps depending on it, module imports, README references). Show any hits to the user and confirm before continuing. If only manifest hits appear, you can proceed without asking.

### 3. Unregister from `hosts/<host>/host-manifest.toml`

Remove the `[[apps]]` block whose `name = "<name>"`, including any `[[apps.dotfiles]]` tables that follow it before the next `[[apps]]`. Use `Edit` with enough surrounding context to make the match unique. Do not use `yq -i`, which drops the blank lines between blocks.

### 4. Delete the app directory

Tell the user clearly:

```
About to delete apps/<name>/ (git-recoverable via `git restore -SW`).
```

Then:

```bash
rm -rf apps/<name>
```

### 5. Report and stop

Print:

```
Removed apps/<name>/ and its entry from hosts/<host>/host-manifest.toml.

Next (run yourself):
  mise run dev:validate-host-config
  mise run refresh
```

Mention the Homebrew zap behavior if the removed app declared `homebrew.brews` / `homebrew.casks`:

> Heads-up: `homebrew.cleanup = "zap"` means the next `nix:apply` will uninstall the Homebrew packages that were only declared in this module.

**Do not** run `mise run refresh`. The user reviews the diff first.

## Notes

- The change is fully recoverable from git until committed (`git restore -SW .` to undo manifest edits + `git restore apps/<name>/` is not enough for a deleted dir; use `git checkout HEAD -- apps/<name>/`).
- Never edit `hosts/<host>/generated/`. That's machine-generated and gitignored.
- `<host>` is the output of `hostname -s`, unless the user names another host.
