# dotfiles

Declarative macOS/Linux system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

This repository provides a fully automated workflow for managing macOS/Linux system configuration and dotfiles using:

-   **[Task](https://taskfile.dev/)** - Modern task runner for all operations
-   **[Nix](https://nixos.org/)** - Reproducible package management
-   **[nix-darwin](https://github.com/LnL7/nix-darwin)** - Declarative macOS system configuration
-   **[GNU Stow](https://www.gnu.org/software/stow/)** - Symlink-based dotfile management
-   **[1Password CLI](https://developer.1password.com/docs/cli/)** - Secure secrets management

### Key Features

-   ✨ **One-command setup** - `task setup-host` handles everything
-   🔒 **Secrets management** - Integration with 1Password for secure secret handling
-   🔄 **Auto-capture** - Watch mode automatically captures dotfile changes
-   ✅ **Validation** - Built-in configuration validation and status checks
-   🎯 **Host-specific** - Different configurations per machine with automatic detection
-   📦 **Reproducible** - Nix ensures consistent environments across machines

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
nix develop --command task --list
```

### Available Tools in Development Shell

The development shell provides:

-   **Task** - Modern task runner for managing workflows
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

### Fresh Machine Setup

```bash
# Clone repository
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Sign in to 1Password
eval $(op signin)

# Bootstrap: Install Nix and nix-darwin (run once per machine)
./bootstrap-scripts/macos-arm64/bootstrap.sh $(hostname -s)

# Restart your shell
exec zsh

# Initialize development shell
./.nix-shell/scripts/init-dev-shell.sh
source ~/.config/zsh/.zshrc

# Complete setup: generate configs, apply, and deploy
task setup-host

# View all available commands
task --list
```

### Already Bootstrapped

If Nix and nix-darwin are already installed:

```bash
cd ~/git-repos/dotfiles
eval $(op signin)
task setup-host  # Generate, deploy Nix, and deploy dotfiles
```

## Dotfiles Workflows

This repository supports two complementary workflows for managing dotfiles:

### Code-First Workflow

Edit templates in the repository, then generate and deploy to your machine with secrets applied.

**Use this when:**

-   Creating new dotfiles
-   Updating existing templates
-   Working in a development container
-   Making changes that should apply to multiple hosts

**Steps:**

```bash
# 1. Edit dotfile templates in apps/*/dotfiles/
vim apps/neovim/dotfiles/init.lua

# 2. Generate dotfiles (applies 1Password secrets)
task generate-all

# 3. Deploy to your home directory (creates symlinks)
task deploy-dotfiles

# Result: Files appear in ~/.config/ with secrets applied
# Example: ~/.config/nvim/init.lua -> hosts/<hostname>/generated/dotfiles/.config/nvim/init.lua
```

**How it works:**

1. `task generate-all` reads templates from `apps/*/dotfiles/`
2. Substitutes `${VARIABLE}` placeholders with values from 1Password
3. Generates files in `hosts/<hostname>/generated/dotfiles/`
4. `task deploy-dotfiles` uses GNU Stow to create symlinks from `~/.config/` to generated files

### Machine-First Workflow

Edit files directly on your machine, then capture changes back to templates with secrets hidden.

**Use this when:**

-   Iterating on configuration (immediate feedback)
-   Testing changes before committing
-   Working on the actual host machine
-   Rapid development (Neovim, shell, etc.)

**Steps:**

```bash
# 1. Edit files directly in your home directory
vim ~/.config/nvim/init.lua
# Changes apply immediately (file is symlinked)

# 2. Capture changes back to source templates
task capture-dotfiles -- --dry-run  # Preview changes
task capture-dotfiles               # Actually capture

# Result: Files in apps/*/dotfiles/ updated with secrets replaced
# Example: apps/neovim/dotfiles/init.lua now has ${MY_SECRET} instead of actual value
```

**How it works:**

1. Edit symlinked files in `~/.config/` (changes write through to `generated/dotfiles/`)
2. `task capture-dotfiles` reads files from `generated/dotfiles/`
3. Replaces actual secret values with `${VARIABLE}` placeholders
4. Copies files back to `apps/*/dotfiles/` templates
5. Safe to commit (no secrets leaked)

### Watch Mode

Auto-capture changes as you edit:

```bash
task watch-dotfiles  # Watches ~/.config/ and auto-captures to source
```

### Recommended Workflow

Combine both approaches for maximum productivity:

```bash
# Initial setup (code-first)
task generate-all && task deploy-dotfiles

# Rapid iteration (machine-first)
task watch-dotfiles              # In one terminal
vim ~/.config/nvim/init.lua  # Edit and test immediately

# Review and commit
git diff apps/neovim/
git commit -am "feat(neovim): improve config"
```

## Task Commands (Recommended)

The Task runner provides an improved workflow with automatic hostname detection, task dependencies, and better developer experience.

### Why Use Task Runner?

-   **Auto-detection**: No need to type hostname repeatedly
-   **Dependencies**: Tasks automatically run prerequisites
-   **Better output**: Clear, formatted status messages
-   **Safety**: Prompts for destructive operations
-   **Watching**: Auto-capture and auto-regenerate capabilities
-   **Validation**: Built-in configuration checks

### Getting Started

```bash
task                    # Show current configuration and available tasks
task check-status       # Show detailed status of configuration
task --list             # List all available tasks
task <task> --summary   # Show detailed help for specific task
```

### Quick Workflows

| Command                 | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `task setup-host`       | Complete setup: generate + deploy-nix + deploy-dotfiles |
| `task refresh-host`     | Regenerate configs and redeploy (no bootstrap)          |
| `task generate-all`     | Generate all configurations (env + nix + dotfiles)      |
| `task deploy-nix`       | Deploy Nix configuration to system                      |
| `task deploy-dotfiles`  | Deploy dotfiles with GNU Stow                           |
| `task capture-dotfiles` | Capture dotfiles back to source (with --dry-run)        |
| `task watch-dotfiles`   | Watch and auto-capture dotfile changes                  |
| `task clean-all`        | Clean generated files                                   |

### Bootstrap Tasks

| Command                              | Description                      |
| ------------------------------------ | -------------------------------- |
| `task bootstrap:generate-env`        | Generate .env from 1Password     |
| `task bootstrap:generate-nix-config` | Generate Nix configuration       |
| `task bootstrap:generate-dotfiles`   | Generate dotfiles from templates |
| `task bootstrap:generate-all`        | Generate all configs             |
| `task bootstrap:apply-config`        | Apply Nix configuration          |
| `task bootstrap:unbootstrap`         | Remove Nix and nix-darwin        |

**Note:** To bootstrap a fresh machine (install Nix/nix-darwin), run the shell script directly:

```bash
./bootstrap-scripts/macos-arm64/bootstrap.sh $(hostname -s)
```

### Dotfiles Tasks

| Command                  | Description                                  |
| ------------------------ | -------------------------------------------- |
| `task dotfiles:deploy`   | Deploy dotfiles with GNU Stow                |
| `task dotfiles:redeploy` | Redeploy (remove and reinstall symlinks)     |
| `task dotfiles:capture`  | Capture changes back to source               |
| `task dotfiles:restore`  | Restore dotfiles from backup                 |
| `task dotfiles:status`   | Show dotfile deployment status               |
| `task dotfiles:diff`     | Show differences between source and deployed |

### Development Tasks

| Command                    | Description                                 |
| -------------------------- | ------------------------------------------- |
| `task dev:watch-dotfiles`  | Watch and auto-capture dotfile changes      |
| `task dev:watch-templates` | Watch templates and auto-regenerate         |
| `task dev:clean`           | Clean generated files                       |
| `task dev:clean-backups`   | Remove all backups                          |
| `task dev:list-hosts`      | List all configured hosts                   |
| `task dev:validate`        | Validate configuration                      |
| `task dev:env`             | Show environment variables                  |
| `task dev:lint`            | Lint all code (shell scripts + Nix files)   |
| `task dev:lint-scripts`    | Lint shell scripts with shellcheck          |
| `task dev:lint-nix`        | Lint Nix files with statix                  |
| `task dev:format`          | Format all code (shell scripts + Nix files) |
| `task dev:format-scripts`  | Format shell scripts with shfmt             |
| `task dev:format-nix`      | Format Nix files with nixpkgs-fmt           |

### Hostname Override

All tasks support hostname override:

```bash
task HOSTNAME=my-other-mac setup-host
task HOSTNAME=my-other-mac check-status
task HOSTNAME=my-other-mac generate-all
```

### Common Workflows

#### Editing Dotfiles

```bash
# 1. Edit dotfiles directly in home directory (changes apply immediately)
vim ~/.config/nvim/init.lua

# 2. Capture changes back to source
task capture-dotfiles -- --dry-run  # Preview changes first
task capture-dotfiles               # Actually capture

# 3. Review and commit
git diff
git commit -am "feat: update neovim config"

# Or use watch mode for automatic capturing
task watch-dotfiles
```

**Key Benefits:**

-   Edit with immediate feedback (no regeneration needed)
-   Automatic secret replacement when capturing back
-   Safe commits (secrets never leak to git)

#### After Changing Templates

```bash
task refresh-host  # Regenerate all configs and redeploy
```

## Bootstrap Workflow

### Fresh Machine

For a completely fresh machine:

```bash
# 1. Bootstrap: Install Nix and nix-darwin (one-time)
./bootstrap-scripts/macos-arm64/bootstrap.sh $(hostname -s)

# 2. Restart your shell to load Nix
exec zsh

# 3. Complete setup
task setup-host
```

The bootstrap script installs Nix and nix-darwin. After that, `task setup-host` handles everything else:

1. **Generate .env** - Extracts secrets from 1Password
2. **Generate Nix config** - Creates system configuration from templates
3. **Generate dotfiles** - Creates dotfiles with variable substitution
4. **Apply configuration** - Installs packages and applies system settings
5. **Deploy dotfiles** - Creates symlinks to your home directory

### Already Bootstrapped

If Nix is already installed, just run:

```bash
task setup-host  # Generate, deploy Nix, and deploy dotfiles
```

### Generated Files

All generated files are created in `hosts/<hostname>/generated/`:

-   `.env` - Environment variables from 1Password
-   `configuration.nix` - System configuration with imported modules
-   `dotfiles/` - Dotfiles with variable substitution
-   `dotfiles-backup-*/` - Backups of original files

## Unbootstrap Workflow

To completely remove the configuration and Nix from your system:

```bash
task dotfiles:restore         # Restore original dotfiles
task bootstrap:unbootstrap    # Remove Nix and nix-darwin
```

This removes:

-   All nix-darwin configurations
-   Nix package manager and all packages
-   All data in `/nix` directory
-   Stow symlinks (replaced with backups)

## Backup Management

Dotfile backups are automatically created during deployment:

-   Location: `hosts/<hostname>/generated/dotfiles-backup-<timestamp>/`
-   Contains: Your original dotfiles before they were replaced with symlinks
-   Restore: `task dotfiles:restore`
-   Restoring removes Stow symlinks and restores your original files

## Customization

### Adding a New Host

```bash
# Copy existing host as template
cp -r hosts/keith-macbook-pro hosts/$(hostname -s)

# Edit configuration files
vim hosts/$(hostname -s)/host-manifest.yml
vim hosts/$(hostname -s)/template.env

# Run setup
task setup-host
```

### Adding Packages

Edit `configuration-template.nix` or add modules via `host-manifest.yml`:

```nix
environment.systemPackages = with pkgs; [
  neovim
  ripgrep
];
```

Then apply changes:

```bash
task refresh-host
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

### Task Runner Issues

```bash
# Verify Task is available
task --version

# Check current configuration
task check-status

# Validate configuration files
task dev:validate

# Show environment variables
task dev:env

# List all available hosts
task dev:list-hosts

# If Task not found, reload development environment
direnv reload
# or
nix develop
```

### Nix Development Shell

```bash
# First time setup
./.nix-shell/scripts/init-dev-shell.sh

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

# Verify authentication (or use task check-status)
op account list
task check-status

# List available vaults
op vault list
```

### Configuration Issues

```bash
# Validate all configuration files
task dev:validate

# Check what's generated
task dev:list-hosts
task dotfiles:status

# Show detailed status
task check-status
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
