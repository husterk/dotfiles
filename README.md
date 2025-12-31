# dotfiles

Declarative macOS system configuration using Nix, nix-darwin, and GNU Stow.

## Quick Setup

**VSCode Users**: See [VSCODE_SETUP.md](VSCODE_SETUP.md) for IDE configuration.

## What This Does

-   Manages system packages and configuration via Nix/nix-darwin
-   Manages dotfiles via GNU Stow with template variable substitution
-   Integrates with 1Password for secure secrets
-   Provides automated workflows via Task runner

## Prerequisites

-   macOS (arm64)
-   1Password CLI: `eval $(op signin)`
-   Nix (installed via bootstrap script)

## Fresh Machine Setup

```bash
# Clone and bootstrap
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles
eval $(op signin)
./bootstrap-scripts/macos-arm64/bootstrap.sh $(hostname -s)

# Restart shell and complete setup
exec zsh
task setup-host
```

## Already Bootstrapped

```bash
cd ~/git-repos/dotfiles
eval $(op signin)
task setup-host
```

## Development Environment

This repo uses Nix flakes + direnv for automatic environment loading:

```bash
cd ~/git-repos/dotfiles  # direnv loads automatically
task --list              # View available commands
```

**Tools included**: task, yq, jq, shellcheck, shfmt, nixpkgs-fmt, nil, neovim, LSPs

**Git hooks**: Automatically installed by dev shell (pre-commit checks: format + lint).

## Common Tasks

### Essential Commands

| Command                 | Description                           |
| ----------------------- | ------------------------------------- |
| `task`                  | Show status and available tasks       |
| `task setup-host`       | Full setup (generate + deploy)        |
| `task refresh-host`     | Regenerate and redeploy               |
| `task deploy-dotfiles`  | Deploy dotfiles with Stow             |
| `task capture-dotfiles` | Capture dotfiles back to templates    |
| `task dev:format`       | Format all code (shell/Nix/YAML/JSON) |
| `task dev:lint`         | Lint all code                         |

### Editing Workflows

**Quick iteration (machine-first):**

```bash
vim ~/.config/nvim/init.lua    # Edit directly (changes apply immediately)
task capture-dotfiles          # Capture back to templates (secrets removed)
git commit -am "fix: config"
```

**With auto-capture:**

```bash
task watch-dotfiles            # Auto-captures changes
vim ~/.config/nvim/init.lua    # Edit and changes auto-capture
```

**Code-first:**

```bash
vim apps/neovim/dotfiles/init.lua  # Edit template
task generate-all                   # Generate with secrets
task deploy-dotfiles                # Deploy to home directory
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

Then: `task refresh-host`

**Add new host:**

```bash
cp -r hosts/keith-macbook-pro hosts/$(hostname -s)
vim hosts/$(hostname -s)/host-manifest.yml
task setup-host
```

## Troubleshooting

**Task not found:**

```bash
direnv reload  # or: nix develop
```

**1Password auth:**

```bash
eval $(op signin)
```

**Nix-darwin issues:**

```bash
darwin-rebuild switch --flake . --show-trace
nix flake check
```

**LSP/formatting not working:**
Ensure you're in dev shell (direnv should auto-load).

## Uninstall

```bash
task dotfiles:restore      # Restore original dotfiles
task bootstrap:unbootstrap # Remove Nix and nix-darwin
```

## Resources

-   [nix-darwin](https://github.com/LnL7/nix-darwin)
-   [Nix Package Search](https://search.nixos.org/packages)
-   [Task](https://taskfile.dev/)
