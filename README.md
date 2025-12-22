# dotfiles

Declarative macOS system configuration using [Nix](https://nixos.org/), [nix-darwin](https://github.com/LnL7/nix-darwin), and [GNU Stow](https://www.gnu.org/software/stow/).

## Prerequisites

Before opening this repository in the VS Code devcontainer, you must run the one-time setup script:

```bash
./one_time_setup.sh
```

This script uses the 1Password CLI to automatically populate the required environment variables for the devcontainer. You must have the [1Password CLI](https://developer.1password.com/docs/cli/get-started/) installed and be signed in.

## Repository Structure

```
dotfiles/
├── bootstrap-scripts/macos-arm/
│   ├── bootstrap.sh          # Idempotent bootstrap script
│   └── darwin-helper.sh      # Helper for common operations
├── dotfiles/                 # User dotfiles (managed by Stow)
├── hosts/<hostname>/         # Host-specific configurations
│   ├── flake.nix            # Nix flake for this host
│   └── configuration.nix    # System configuration
└── modules/                  # Composable Nix modules
    ├── common.nix           # OS-agnostic packages/settings
    ├── macos.nix            # macOS-specific settings
    └── development.nix      # Development tools
```

## Quick Start

```bash
# Clone repository
git clone https://github.com/husterk/dotfiles ~/git-repos/dotfiles
cd ~/git-repos/dotfiles

# Create host configuration for your machine
# Use existing host as template: cp -r hosts/keith-macbook-pro hosts/$(hostname -s)

# Run bootstrap script (installs Nix, nix-darwin, configures system)
./bootstrap-scripts/macos-arm/bootstrap.sh
```

## Common Commands

```bash
# Apply configuration changes
./bootstrap-scripts/macos-arm/darwin-helper.sh switch

# Update packages and rebuild
./bootstrap-scripts/macos-arm/darwin-helper.sh upgrade

# Rollback to previous generation
./bootstrap-scripts/macos-arm/darwin-helper.sh rollback

# Search for packages
nix search nixpkgs <package-name>

# Stow dotfiles
cd dotfiles && stow vim zsh git
```

## Customization

### Adding a New Host

```bash
# Get your hostname
hostname -s

# Copy existing host as template
cp -r hosts/keith-macbook-pro hosts/your-hostname

# Edit hosts/your-hostname/flake.nix to update hostname
# Edit hosts/your-hostname/configuration.nix for host-specific settings
```

### Adding Packages

Edit your host's `configuration.nix`:

```nix
environment.systemPackages = with pkgs; [
  neovim
  ripgrep
];
```

### Creating Modules

Create reusable modules in `modules/` and import them in your host's `configuration.nix`:

```nix
imports = [
  ../../modules/common.nix
  ../../modules/macos.nix
];
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
