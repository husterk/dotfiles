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
# Clone repository
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Bootstrap your macOS host (installs Nix, nix-darwin, GNU Stow)
./dotfiles bootstrap

# Generate and apply configuration
./dotfiles generate-config $(hostname -s)
./dotfiles generate-dotfiles $(hostname -s)
./dotfiles apply-config $(hostname -s)
./dotfiles deploy-dotfiles $(hostname -s)
```

## Management Commands

The `./dotfiles` script provides a unified interface for all operations:

```bash
./dotfiles <command> [hostname]
```

### Available Commands

| Command             | Description                                                        |
| ------------------- | ------------------------------------------------------------------ |
| `bootstrap`         | Bootstrap a new macOS host with Nix and nix-darwin                 |
| `generate-config`   | Generate Nix configuration from templates (with 1Password secrets) |
| `generate-dotfiles` | Generate dotfiles from templates                                   |
| `apply-config`      | Apply Nix configuration to the system (requires sudo)              |
| `deploy-dotfiles`   | Deploy dotfiles using GNU Stow                                     |
| `restore-dotfiles`  | Restore dotfiles from backup (removes Stow symlinks)               |
| `unbootstrap`       | Remove Nix and nix-darwin from system                              |
| `help`              | Show help message                                                  |

**Note:** If hostname is not provided, the current hostname will be detected automatically.

## Configuration Workflow

This repository uses a four-step workflow to manage your system configuration and dotfiles:

### 1. Bootstrap (One-time Setup)

Install Nix package manager, nix-darwin, and GNU Stow:

```bash
./dotfiles bootstrap
```

### 2. Generate Nix Configuration

Generate nix-darwin configuration from templates with 1Password secret injection:

```bash
./dotfiles generate-config $(hostname -s)

# Or let it auto-detect hostname:
./dotfiles generate-config

# Files generated in hosts/<hostname>/generated/:
#   - .env                    # Environment variables from 1Password
#   - configuration.nix       # System configuration with imported modules
```

### 3. Generate Dotfiles

Generate dotfiles from templates with environment variable substitution:

```bash
./dotfiles generate-dotfiles $(hostname -s)

# Files generated in hosts/<hostname>/generated/:
#   - dotfiles/               # Dotfiles with variable substitution
```

### 4. Apply Configuration

Apply the nix-darwin system configuration (handles git staging automatically):

```bash
./dotfiles apply-config $(hostname -s)

# This command:
#   - Temporarily stages configuration.nix in git (required by nix flakes)
#   - Runs darwin-rebuild switch --flake
#   - Cleans up staged files (keeps secrets out of git history)
```

### 5. Deploy Dotfiles

Deploy dotfiles to your home directory using GNU Stow:

```bash
# Preview what will be deployed (recommended first time)
./dotfiles deploy-dotfiles $(hostname -s) --dry-run

# Deploy dotfiles (automatically backs up existing files)
./dotfiles deploy-dotfiles $(hostname -s)
```

## Common Commands

```bash
# Regenerate configuration after making changes
./dotfiles generate-config
./dotfiles generate-dotfiles
./dotfiles apply-config
./dotfiles deploy-dotfiles

# Update existing dotfiles after changes
./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $(hostname -s) --restow

# Restore dotfiles from a previous backup
./dotfiles restore-dotfiles

# Remove Nix and nix-darwin completely
./dotfiles unbootstrap

# Low-level nix-darwin operations (advanced)
./bootstrap-scripts/macos-arm64/darwin-helper.sh switch
./bootstrap-scripts/macos-arm64/darwin-helper.sh rollback
./bootstrap-scripts/macos-arm64/darwin-helper.sh list

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
./dotfiles generate-config $(hostname -s)
./dotfiles generate-dotfiles $(hostname -s)
./dotfiles apply-config $(hostname -s)
./dotfiles deploy-dotfiles $(hostname -s)
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
./dotfiles generate-config $(hostname -s)
./dotfiles apply-config $(hostname -s)
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
