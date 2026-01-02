# dotfiles

Declarative macOS system configuration using Nix, nix-darwin, and GNU Stow.

## Quick Setup

**VSCode Users**: See [VSCODE_SETUP.md](VSCODE_SETUP.md) for IDE configuration.

## What This Does

- Manages system packages and configuration via Nix/nix-darwin
- Manages dotfiles via GNU Stow with template variable substitution
- Integrates with 1Password for secure secrets
- Provides automated workflows via Task runner

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
task set-up-new-host
```

## Already Bootstrapped

```bash
cd ~/git-repos/dotfiles
op signin
task refresh-host
```

## Development Environment

This repo uses Nix flakes + direnv for automatic environment loading:

```bash
cd ~/git-repos/dotfiles  # direnv loads automatically
task                     # View available commands
```

**Tools included**: task, yq, jq, shellcheck, shfmt, nixpkgs-fmt, nil, neovim, LSPs

**Git hooks**: Automatically installed by dev shell (pre-commit checks: format + lint).

## Common Tasks

### Essential Commands

| Command                | Description                     |
| ---------------------- | ------------------------------- |
| `task`                 | Show status and available tasks |
| `task set-up-new-host` | Full setup (generate + deploy)  |
| `task refresh-host`    | Regenerate and redeploy         |

### Dotfiles Editing Workflows

**Quick iteration (machine-first):**

```bash
vim ~/.config/nvim/init.lua    # Edit directly (changes apply immediately)
task dotfiles:capture          # Capture back to templates (secrets removed)
git commit -am "fix: config"
```

**With auto-capture:**

```bash
task dotfiles:watch-host       # Auto-captures changes
vim ~/.config/nvim/init.lua    # Edit and changes auto-capture
```

**Code-first:**

```bash
vim apps/neovim/dotfiles/init.lua  # Edit template
task dotfiles:generate             # Generate with secrets
task dotfiles:deploy               # Deploy to home directory
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
task set-up-new-host
```

## Troubleshooting

**Task not found:**

```bash
direnv reload  # or: nix develop
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
Ensure you're in dev shell (direnv should auto-load).

## Uninstall

```bash
task dotfiles:restore   # Restore original dotfiles
task unbootstrap        # Remove Nix and nix-darwin
```

## Resources

- [nix-darwin](https://github.com/LnL7/nix-darwin)
- [Nix Package Search](https://search.nixos.org/packages)
- [Task](https://taskfile.dev/)
