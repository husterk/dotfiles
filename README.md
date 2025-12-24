# dotfiles

Declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

This script uses the 1Password CLI to automatically populate the required environment variables for the devcontainer. You must have the [1Password CLI](https://developer.1password.com/docs/cli/get-started/) installed and be signed in.

## Repository Structure

```
dotfiles/
├── .devcontainer/              # VS Code devcontainer configuration
├── bootstrap-scripts/
│   └── macos-arm64/
│       ├── bootstrap.sh        # Initial system setup (Nix, nix-darwin, Stow)
│       ├── generate-config.sh  # Generate configs from templates with secrets
│       ├── apply-config.sh     # Apply nix-darwin configuration
│       └── deploy-dotfiles.sh  # Deploy dotfiles with GNU Stow
├── hosts/<hostname>/
│   ├── flake.nix              # Nix flake entry point
│   ├── template.env           # 1Password secret references
│   ├── template.nix           # System configuration template
│   ├── host-manifest.yml      # Declarative module and dotfile specification
│   └── generated/             # Generated files (gitignored, contains secrets)
│       ├── .env
│       ├── configuration.nix
│       └── dotfiles/
├── apps/                       # Application-specific configs and dotfiles
│   └── <app-name>/
│       ├── <app-name>.nix     # Nix module for the app
│       └── <dotfiles>         # App dotfiles (templates)
└── modules/                    # Reusable Nix modules
    ├── nix-base.nix
    └── macos-base.nix
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Create host configuration for your machine
# Use existing host as template: cp -r hosts/keith-macbook-pro hosts/$(hostname -s)

# HOST TERMINAL SESSION: Run bootstrap script (installs Nix, nix-darwin, GNU Stow).
./bootstrap-scripts/macos-arm64/bootstrap.sh
```

## Configuration Workflow

This repository uses a three-step workflow to manage your system configuration and dotfiles:

### 1. Generate Configuration

Generate nix-darwin configuration and dotfiles from templates with 1Password secret injection:

```bash
# DEVCONTAINER/HOST TERMINAL SESSION: Generate configuration for your host
./bootstrap-scripts/macos-arm64/generate-config.sh $(hostname -s)

# Files generated in hosts/<hostname>/generated/:
#   - .env                    # Environment variables from 1Password
#   - configuration.nix       # System configuration with imported modules
#   - dotfiles/               # Dotfiles with environment variable substitution
```

### 2. Apply System Configuration

Apply the nix-darwin system configuration (handles git staging automatically):

```bash
# HOST TERMINAL SESSION: Apply configuration (requires sudo)
./bootstrap-scripts/macos-arm64/apply-config.sh $(hostname -s)

# This script:
#   - Temporarily stages configuration.nix in git (required by nix flakes)
#   - Runs darwin-rebuild switch --flake
#   - Cleans up staged files (keeps secrets out of git history)
```

### 3. Deploy Dotfiles

Deploy dotfiles to your home directory using GNU Stow:

```bash
# HOST TERMINAL SESSION: Preview what will be deployed (recommended first time)
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --dry-run

# HOST TERMINAL SESSION: Deploy dotfiles (automatically backs up existing files)
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s)

# HOST TERMINAL SESSION: Update existing dotfiles after changes
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --restow

# HOST TERMINAL SESSION: Remove dotfile symlinks
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --delete

# HOST TERMINAL SESSION: Restore dotfiles from a previous backup
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --restore
```

**Backup Management:**

- Backups are automatically created before deployment in `hosts/<hostname>/generated/dotfiles-backup-<timestamp>/`
- Each backup contains your original dotfiles before they were replaced with symlinks
- Use `--restore` to interactively select and restore from any previous backup
- Restoring will remove Stow symlinks and restore your original files

### Complete Workflow Example

```bash
# 1. DEVCONTAINER/HOST TERMINAL SESSION: Generate configs and dotfiles from templates
./bootstrap-scripts/macos-arm64/generate-config.sh $(hostname -s)

# 2. HOST TERMINAL SESSION: Apply nix-darwin system configuration
./bootstrap-scripts/macos-arm64/apply-config.sh $(hostname -s)

# 3. HOST TERMINAL SESSION: Deploy dotfiles with Stow
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s)
```

**Note:** Generated files in `hosts/<hostname>/generated/` contain secrets and are gitignored. They should never be committed to version control.

## Common Commands

```bash
# HOST TERMINAL SESSION COMMANDS:
# Regenerate and reapply configuration after making changes
./bootstrap-scripts/macos-arm64/generate-config.sh $(hostname -s)
./bootstrap-scripts/macos-arm64/apply-config.sh $(hostname -s)
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --restow

# Search for packages
nix search nixpkgs <package-name>

# View previous system generations
darwin-rebuild --list-generations

# Rollback to previous generation
darwin-rebuild rollback --flake .
```

## Customization

### Adding a New Host

```bash
# Get your hostname
hostname -s

# Copy existing host as template
cp -r hosts/keith-macbook-pro hosts/$(hostname -s)

# Edit the host manifest
vim hosts/$(hostname -s)/host-manifest.yml

# Update template.env with your 1Password secret references
vim hosts/$(hostname -s)/template.env

# Generate and apply configuration
./bootstrap-scripts/macos-arm64/generate-config.sh $(hostname -s)
./bootstrap-scripts/macos-arm64/apply-config.sh $(hostname -s)
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s)
```

### Adding Packages

Edit your host's `host-manifest.yml` to add application modules, or directly edit `template.nix`:

```nix
environment.systemPackages = with pkgs; [
  neovim
  ripgrep
];
```

After making changes, regenerate and apply:

```bash
./bootstrap-scripts/macos-arm64/generate-config.sh $(hostname -s)
./bootstrap-scripts/macos-arm64/apply-config.sh $(hostname -s)
```

### Creating Modules

Create reusable modules in `modules/` or application-specific modules in `apps/<app-name>/`:

```nix
# apps/myapp/myapp.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    myapp
  ];
}
```

Reference them in your `host-manifest.yml`:

```yaml
apps:
    - name: myapp
      modules:
          - /apps/myapp/myapp.nix
      dotfiles:
          - source: /apps/myapp/.myapprc
            target: ~/.myapprc
```

## Troubleshooting

```bash
# Show detailed build errors
darwin-rebuild switch --flake . --show-trace

# Check flake syntax
nix flake check

# Verify hostname matches directory
hostname -s && ls -1 hosts/

# Source Nix in current shell
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## Resources

- [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
- [Nix Package Search](https://search.nixos.org/packages)
- [nix-darwin Options](https://daiderd.com/nix-darwin/manual/index.html)
