# dotfiles

Declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

This script uses the 1Password CLI to automatically populate the required environment variables for the devcontainer. You must have the [1Password CLI](https://developer.1password.com/docs/cli/get-started/) installed and be signed in.

## Repository Structure

```
dotfiles/
├── dotfiles                    # Main management script (unified interface)
├── .devcontainer/              # VS Code devcontainer configuration
│   ├── scripts/               # Devcontainer lifecycle scripts
│   │   ├── initialize.sh      # Pre-build: Generate .env from 1Password
│   │   ├── post-create.sh     # Post-create: Setup SSH, shell integration, packages
│   │   └── ssh-to-host.sh     # SSH wrapper for host terminal access
│   ├── devcontainer.json
│   ├── docker-compose.devcontainer.yml
│   └── Dockerfile
├── bootstrap-scripts/          # OS/architecture-specific bootstrap scripts
│   └── <target>/              # e.g., macos-arm64, linux-x86_64, etc.
│       ├── bootstrap.sh             # Initial system setup (Nix, nix-darwin, Stow)
│       ├── generate-nix-config.sh   # Generate Nix config from templates
│       ├── generate-dotfiles.sh     # Generate dotfiles from templates
│       ├── apply-config.sh          # Apply nix-darwin configuration
│       ├── deploy-dotfiles.sh       # Deploy dotfiles with GNU Stow
│       ├── unbootstrap.sh           # Remove Nix and nix-darwin
│       └── darwin-helper.sh         # Low-level nix-darwin operations
├── hosts/<hostname>/
│   ├── flake.nix              # Nix flake entry point
│   ├── template.env           # 1Password secret references
│   ├── configuration-template.nix  # System configuration template
│   ├── host-manifest.yml      # Declarative module and dotfile specification
│   │                          # (includes bootstrap-target for OS/arch selection)
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
# Clone repository (on host)
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Open in VS Code with devcontainer
code .

# In devcontainer terminal:
./dotfiles generate-env keith-macbook-pro            # Generate .env from 1Password
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles generate-dotfiles keith-macbook-pro

# In host terminal:
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
| `generate-nix-config` | Generate Nix configuration from templates (with 1Password secrets) |
| `generate-dotfiles`   | Generate dotfiles from templates                                   |
| `apply-nix-config`    | Apply Nix configuration to the system (requires sudo)              |
| `deploy-dotfiles`     | Deploy dotfiles using GNU Stow                                     |
| `restore-dotfiles`    | Restore dotfiles from backup (removes Stow symlinks)               |
| `unbootstrap`         | Remove Nix and nix-darwin from system                              |
| `help`                | Show help message                                                  |

**Note:** Hostname is REQUIRED for all commands to prevent unintended operations.

## Bootstrap Workflow

This repository uses a 6-step workflow to bootstrap and configure a new host:

### 1. Generate Environment Variables (in devcontainer)

Generate .env file from 1Password secrets:

```bash
# Run from devcontainer terminal (only needed when secrets change)
./dotfiles generate-env keith-macbook-pro

# Files generated in hosts/<hostname>/generated/:
#   - .env                    # Environment variables from 1Password
```

**Note:** This step only needs to be run when your 1Password secrets change. The .env file will be reused by subsequent commands.

### 2. Generate Nix Configuration (in devcontainer)

Generate nix-darwin configuration from templates:

```bash
# Run from devcontainer terminal
./dotfiles generate-nix-config keith-macbook-pro

# Files generated in hosts/<hostname>/generated/:
#   - configuration.nix       # System configuration with imported modules

# Note: If .env doesn't exist, this will generate it automatically from 1Password
```

### 3. Generate Dotfiles (in devcontainer)

Generate dotfiles from templates with environment variable substitution:

```bash
# Run from devcontainer terminal
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

## Common Commands

```bash
# Regenerate .env when secrets change (devcontainer)
./dotfiles generate-env keith-macbook-pro

# Regenerate configuration after making changes (devcontainer)
./dotfiles generate-nix-config keith-macbook-pro
./dotfiles generate-dotfiles keith-macbook-pro

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

- Location: `hosts/<hostname>/generated/dotfiles-backup-<timestamp>/`
- Contains: Your original dotfiles before they were replaced with symlinks
- Restore: `./dotfiles restore-dotfiles $(hostname -s)`
- Restoring removes Stow symlinks and restores your original files

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
