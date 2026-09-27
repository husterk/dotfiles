# dotfiles

Declarative macOS system configuration using Nix, nix-darwin, and GNU Stow.

## Quick Setup

**VSCode Users**: See [VSCODE_SETUP.md](VSCODE_SETUP.md) for IDE configuration.

## What This Does

- Manages system packages and configuration via Nix/nix-darwin
- Manages dotfiles via GNU Stow with template variable substitution
- Integrates with 1Password for secure secrets
- Provides automated workflows via mise tasks

## Prerequisites

- macOS (arm64)
- 1Password CLI: `op signin`
- Nix (installed via bootstrap script)

## Fresh Machine Setup

```bash
# Clone and bootstrap
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles
op signin
./bootstrap-scripts/macos-arm64/bootstrap.sh $(hostname -s)

# Restart shell and complete setup
exec zsh
mise run setup
```

## Already Bootstrapped

```bash
cd ~/git-repos/dotfiles
op signin
mise run refresh
```

## Development Environment

This repo uses mise for development tooling and task management:

```bash
cd ~/git-repos/dotfiles  # mise activates automatically
mise run                 # View available commands
mise tasks               # List all tasks
```

**Tools included**: task, yq, jq, shellcheck, shfmt, prettier, stylua, taplo, neovim, LSPs

**Checks**: `mise run check` runs the same gates as CI. There is no pre-commit hook.

### Continuous Integration

`.github/workflows/ci.yml` runs on every pull request and on pushes to `main`,
enforcing the same gates as `mise run check`, so automated PRs (Renovate)
can't land code that fails them.

| Check                          | Task                              |
| ------------------------------ | --------------------------------- |
| Lockfile checksums are valid   | `mise install --locked`           |
| `mise.lock` matches pins       | `mise run dev:check-tool-pins`    |
| Host manifests are valid       | `mise run dev:validate-all-hosts` |
| Formatting is clean            | `mise run dev:format-check`       |
| Lint, tool sync, prose, skills | `mise run dev:lint`               |

`dev:lint` fans out to shellcheck, statix, the mise/Nix tool-sync check, the US
spelling scanner over tracked Markdown, and a structural audit of the Claude
skill and agent definitions. Run any of them alone with
`mise run dev:check-spelling` or `mise run dev:check-skills`.

Every task above is runnable locally, and CI installs `nixfmt`/`statix`/
`treefmt` from the same nixpkgs revision the host builds from, so results match
your machine.

**CI does not build the Nix configuration.** `hosts/<host>/flake.nix` imports
`./configuration.nix`, which is generated from `configuration-template.nix`
using 1Password secrets and is gitignored, so a runner can't evaluate the flake.
CI validates sources; only `mise run nix:apply` proves the system builds.

## Common Tasks

### Essential Commands

| Command            | Description                     |
| ------------------ | ------------------------------- |
| `mise run`         | Show status and available tasks |
| `mise run setup`   | Full setup (generate + deploy)  |
| `mise run refresh` | Regenerate and redeploy         |

### Dotfiles Editing Workflows

**Quick iteration (machine-first):**

```bash
vim ~/.config/nvim/init.lua       # Edit directly (changes apply immediately)
mise run dotfiles:capture         # Capture back to templates (secrets removed)
git commit -am "fix: config"
```

**With auto-capture:**

```bash
mise run dotfiles:watch-host      # Auto-captures changes (if available)
vim ~/.config/nvim/init.lua       # Edit and changes auto-capture
```

**Code-first:**

```bash
vim apps/neovim/dotfiles/init.lua  # Edit template
mise run dotfiles:generate         # Generate with secrets
mise run dotfiles:deploy           # Deploy to home directory
```

## Repository Structure

```
apps/<app>/              # Application configs
  <app>.nix              # Nix module
  dotfiles/              # Dotfile templates (with ${VARS})
hosts/<hostname>/        # Host-specific configuration
  host-manifest.yml      # Module and dotfile declarations
  template.env           # 1Password secret references
  configuration-template.nix
  generated/             # Generated files (gitignored, contains secrets)
    .env                 # Environment from 1Password
    configuration.nix    # Generated Nix config
    dotfiles/            # Generated dotfiles (secrets applied)
```

## Customization

**Add packages:**

```nix
# Edit hosts/<hostname>/configuration-template.nix
environment.systemPackages = with pkgs; [ ripgrep ];
```

Then: `mise run refresh`

**Add new host:**

```bash
cp -r hosts/keith-macbook-pro hosts/$(hostname -s)
vim hosts/$(hostname -s)/host-manifest.yml
mise run setup
```

## Troubleshooting

**mise not activating:**

```bash
exec zsh  # Restart shell
mise doctor  # Check mise status
```

**1Password auth:**

```bash
op signin
```

**Nix-darwin issues:**

```bash
darwin-rebuild switch --flake . --show-trace
nix flake check
```

**LSP/formatting not working:**
Ensure mise is activated and tools are installed: `mise doctor`

## Uninstall

```bash
mise run dotfiles:restore   # Restore original dotfiles (if task exists)
mise run unbootstrap        # Remove Nix and nix-darwin (if task exists)
```

## Resources

- [mise](https://mise.jdx.dev/)
- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Nix Package Search](https://search.nixos.org/packages)
