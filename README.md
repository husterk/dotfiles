# dotfiles

Declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

### Required

-   **macOS** (arm64 architecture)
-   **Nix Package Manager** (installed via bootstrap process)
-   **1Password CLI** (`op`) - [Installation Guide](https://developer.1password.com/docs/cli/get-started/)
    -   Must be signed in: `eval $(op signin)`

### Recommended

-   **direnv** - Automatically loads Nix development shell
    -   Will be installed automatically during setup if missing
-   **Neovim** - Included in development shell with LSPs
    │ ├── apply-config.sh # Apply nix-darwin configuration
    │ ├── deploy-dotfiles.sh # Deploy dotfiles with GNU Stow
    │ ├── unbootstrap.sh # Remove Nix and nix-darwin
    │ └── darwin-helper.sh # Low-level nix-darwin operations
    ├── hosts/<hostname>/
    │ ├── flake.nix # Nix flake entry point
    │ ├── template.env # 1Password secret references
    │ ├── configuration-template.nix # System configuration template
    │ ├── host-manifest.yml # Declarative module and dotfile specification
    │ │ # (includes bootstrap-target for OS/arch selection)
    │ └── generated/ # Generated files (gitignored, contains secrets)
    │ ├── .env
    │ ├── configuration.nix
    │ └── dotfiles/
    ├── apps/ # Application-specific configs and dotfiles
    │ └── <app-name>/
    │ ├── <app-name>.nix # Nix module for the app
    │ └── <dotfiles> # App dotfiles (templates)
    └── modules/ # Reusable Nix modules
    ├── nix-base.nix
    └── macos-base.nix

````

## Development Environment

This repository uses **Nix flakes** to provide a reproducible development environment with all required tools.

### Automatic Setup (Recommended)

When you navigate to this directory, `direnv` will automatically load the development shell:

```bash
cd ~/git-repos/dotfiles
# direnv: loading ~/git-repos/dotfiles/.envrc
# 🚀 Dotfiles development environment loaded
````

### Manual Setup

If you prefer not to use direnv:

```bash
# Enter development shell manually
nix develop

# Or run a single command in the shell
nix develop --command ./dotfiles --help
```

### Available Tools in Development Shell

The development shell provides:

-   **yq** - YAML processor for parsing manifests
-   **1Password CLI** (`op`) - Secret management
-   **ShellCheck** - Shell script linting and validation
-   **shfmt** - Shell script formatter
-   **Nix tools** - nil (LSP), nixpkgs-fmt, statix
-   **Neovim** - With LSPs for Bash, Lua, Markdown, and Nix

### Neovim Integration

Neovim automatically inherits the development environment:

```bash
cd ~/git-repos/dotfiles
# direnv loads automatically

nvim  # Launch Neovim - all tools and LSPs are available
```

## Quick Start

```bash
# Clone repository (on host)
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Sign in to 1Password (required for generating .env with secrets)
eval $(op signin)

# Initialize development shell (first time only)
# This will generate .env from 1Password secrets and configure direnv
./.nix-shell/scripts/init-dev-shell.sh

# Restart your shell
source ~/.config/zsh/.zshrc

# Development shell will now load automatically via direnv
# All tools are available in your PATH

# Generate environment and configuration
./dotfiles generate-env keith-macbook-pro
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles generate-dotfiles keith-macbook-pro

# Bootstrap and apply (on host)
./dotfiles bootstrap keith-macbook-pro
./dotfiles apply-nix-config keith-macbook-pro
./dotfiles deploy-dotfiles keith-macbook-pro
```

## Management Commands

The `./dotfiles` script provides a unified interface for all operations:

```bash
./dotfiles <command> [hostname]
```

### Available Commands

| Command               | Description                                                        |
| --------------------- | ------------------------------------------------------------------ |
| `bootstrap`           | Bootstrap a new host with Nix and nix-darwin                       |
| `generate-env`        | Generate .env file from 1Password secrets                          |
| `generate-nix-config` | Generate Nix configuration from templates (with 1Password secrets) |
| `generate-dotfiles`   | Generate dotfiles from templates                                   |
| `sync-dotfiles`       | Sync generated dotfiles back to source (with secret replacement)   |
| `apply-nix-config`    | Apply Nix configuration to the system (requires sudo)              |
| `deploy-dotfiles`     | Deploy dotfiles using GNU Stow                                     |
| `restore-dotfiles`    | Restore dotfiles from backup (removes Stow symlinks)               |
| `unbootstrap`         | Remove Nix and nix-darwin from system                              |
| `help`                | Show help message                                                  |

**Note:** Hostname is REQUIRED for all commands to prevent unintended operations.

## Bootstrap Workflow

This repository uses a 6-step workflow to bootstrap and configure a new host:

### 1. Generate Environment Variables (in development shell)

Generate .env file from 1Password secrets:

```bash
# Run from development shell (only needed when secrets change)
./dotfiles generate-env keith-macbook-pro

# Files generated in hosts/<hostname>/generated/:
#   - .env                    # Environment variables from 1Password
```

**Note:** This step only needs to be run when your 1Password secrets change. The .env file will be reused by subsequent commands.

### 2. Generate Nix Configuration (in development shell)

Generate nix-darwin configuration from templates:

```bash
# Run from development shell
./dotfiles generate-nix-config keith-macbook-pro

# Files generated in hosts/<hostname>/generated/:
#   - configuration.nix       # System configuration with imported modules

# Note: If .env doesn't exist, this will generate it automatically from 1Password
```

### 3. Generate Dotfiles (in development shell)

Generate dotfiles from templates with environment variable substitution:

```bash
# Run from development shell
./dotfiles generate-dotfiles keith-macbook-pro

# Files generated in hosts/<hostname>/generated/:
#   - dotfiles/               # Dotfiles with variable substitution
```

### 4. Bootstrap Host (on host)

Install Nix package manager, nix-darwin, and GNU Stow on the host:

```bash
# Run from host terminal (one-time setup)
./dotfiles bootstrap keith-macbook-pro

# This installs:
#   - Nix package manager (via Determinate Systems installer)
#   - nix-darwin (declarative macOS configuration)
#   - GNU Stow (dotfile symlink manager)
```

### 5. Apply Nix Configuration (on host)

Apply the nix-darwin system configuration (handles git staging automatically):

```bash
# Run from host terminal
./dotfiles apply-nix-config keith-macbook-pro

# This command:
#   - Temporarily stages configuration.nix in git (required by nix flakes)
#   - Runs darwin-rebuild switch --flake
#   - Installs all packages defined in configuration
#   - Cleans up staged files (keeps secrets out of git history)
```

### 6. Deploy Dotfiles (on host)

Deploy dotfiles to your home directory using GNU Stow:

```bash
# Run from host terminal

# Preview what will be deployed (recommended first time)
./dotfiles deploy-dotfiles keith-macbook-pro --dry-run

# Deploy dotfiles (automatically backs up existing files)
./dotfiles deploy-dotfiles keith-macbook-pro
```

## Unbootstrap Workflow

To completely remove the configuration and Nix from your system:

### 1. Restore Dotfiles (on host)

Restore your original dotfiles from backup:

```bash
# Run from host terminal
./dotfiles restore-dotfiles keith-macbook-pro

# This removes Stow symlinks and restores your original files
```

### 2. Unbootstrap System (on host)

Remove Nix, nix-darwin, and all packages:

```bash
# Run from host terminal
./dotfiles unbootstrap keith-macbook-pro

# This removes:
#   - All nix-darwin configurations
#   - Nix package manager and all packages
#   - All data in /nix directory
```

## Iterating on Dotfiles

Once deployed, GNU Stow creates symlinks from `~/.config/` to your generated dotfiles. This means you can edit files directly and see changes immediately:

```bash
# On host: Edit the symlinked file (changes apply immediately)
nvim ~/.config/nvim/init.lua

# In development shell: Sync changes back to source
./dotfiles sync-dotfiles keith-macbook-pro --dry-run  # Preview changes
./dotfiles sync-dotfiles keith-macbook-pro            # Apply sync

# Review and commit
git diff apps/neovim/init.lua
git commit -am "feat(neovim): improve configuration"
```

**Key Benefits:**

-   Edit with immediate feedback (no regeneration needed)
-   Automatic secret replacement when syncing back
-   Safe commits (secrets never leak to git)
-   Perfect for configs requiring rapid iteration (Neovim, shell, etc.)

## Common Commands

```bash
# Regenerate .env when secrets change (development shell)
./dotfiles generate-env keith-macbook-pro

# Regenerate configuration after making changes (development shell)
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles generate-dotfiles keith-macbook-pro

# Sync dotfile changes back to source (development shell)
./dotfiles sync-dotfiles keith-macbook-pro --dry-run  # Preview
./dotfiles sync-dotfiles keith-macbook-pro            # Apply

# Apply changes (host)
./dotfiles apply-nix-config keith-macbook-pro
./dotfiles deploy-dotfiles keith-macbook-pro

# Update existing dotfiles after changes (host)
./dotfiles deploy-dotfiles keith-macbook-pro --restow

# Restore dotfiles from a previous backup (host)
./dotfiles restore-dotfiles keith-macbook-pro

# Remove Nix and nix-darwin completely (host)
./dotfiles unbootstrap keith-macbook-pro

# Low-level nix-darwin operations (advanced, on host)
./bootstrap-scripts/macos-arm64/darwin-helper.sh switch keith-macbook-pro
./bootstrap-scripts/macos-arm64/darwin-helper.sh rollback keith-macbook-pro
./bootstrap-scripts/macos-arm64/darwin-helper.sh list keith-macbook-pro

# Search for packages
nix search nixpkgs <package-name>
```

## Backup Management

Dotfile backups are automatically created during deployment:

-   Location: `hosts/<hostname>/generated/dotfiles-backup-<timestamp>/`
-   Contains: Your original dotfiles before they were replaced with symlinks
-   Restore: `./dotfiles restore-dotfiles $(hostname -s)`
-   Restoring removes Stow symlinks and restores your original files

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
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles generate-dotfiles keith-macbook-pro
./dotfiles apply-nix-config keith-macbook-pro
./dotfiles deploy-dotfiles keith-macbook-pro
```

### Adding Packages

Edit your host's `host-manifest.yml` to add application modules, or directly edit `configuration-template.nix`:

```nix
environment.systemPackages = with pkgs; [
  neovim
  ripgrep
];
```

After making changes, regenerate and apply:

```bash
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles apply-nix-config keith-macbook-pro
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

### Nix Development Shell

```bash
# First time setup
./scripts/init-dev-shell.sh

# Check if direnv is working
direnv status

# Reload direnv manually
direnv allow
direnv reload

# Enter shell manually if direnv issues
nix develop

# Update flake inputs
nix flake update

# Check flake syntax
nix flake check
```

### 1Password CLI Authentication

```bash
# Sign in to 1Password
eval $(op signin)

# Verify authentication
op account list

# List available vaults
op vault list
```

### Neovim LSP Issues

```bash
# Verify LSPs are available in the shell
which bash-language-server
which lua-language-server
which nil
which marksman

# Inside Neovim, check LSP status
:LspInfo
:checkhealth lsp
```

### Nix-darwin Issues

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

-   [nix-darwin Documentation](https://github.com/LnL7/nix-darwin)
-   [Nix Package Search](https://search.nixos.org/packages)
-   [nix-darwin Options](https://daiderd.com/nix-darwin/manual/index.html)
