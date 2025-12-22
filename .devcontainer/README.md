# Development Container Configuration

This directory contains the configuration for a standardized development environment using VS Code Dev Containers.

## Structure

- `devcontainer.json` - Main configuration file for VS Code Dev Containers
- `Dockerfile` - Multi-stage container definition for the development environment
- `docker-compose.devcontainer.yml` - Docker Compose configuration for the dev container
- `.env.template` - Template for environment variables needed by the container

## Features

- Ubuntu-based development environment
- Bun runtime and package manager
- 1Password CLI integration via feature `ghcr.io/flexwie/devcontainer-features/op:1`
- Customized VS Code settings and extensions
- Persistent node_modules volume for improved performance
- Zsh as default terminal shell

## Setup

The `.env` file is automatically created by the `one_time_setup.sh` script in the repository root (see main README). Once the script has been run, simply open the project in VS Code and click "Reopen in Container" when prompted.

## Container Lifecycle

The container includes three key lifecycle commands:

- `initializeCommand` - Runs on the host before container creation
- `postCreateCommand` - Runs inside container after creation (`bun install --frozen-lockfile`)
- `postStartCommand` - Runs inside container each time it starts

## Included VS Code Extensions

### Development Tools

- **1Password** (`1Password.op-vscode`) - Secrets and password management
- **Docker** (`ms-azuretools.vscode-docker`) - Container management and support
- **Prettier** (`esbenp.prettier-vscode`) - Code formatter
- **EditorConfig** (`EditorConfig.EditorConfig`) - Consistent coding styles
- **Bun** (`oven.bun-vscode`) - Bun runtime support

### Nix Development

- **Nix IDE** (`jnoortheen.nix-ide`) - Nix language support, syntax highlighting, and LSP
- **Nix Environment Selector** (`arrterian.nix-env-selector`) - Switch between Nix environments

### Shell & Dotfiles

- **ShellCheck** (`timonwong.shellcheck`) - Shell script linting
- **Shell Format** (`foxundermoon.shell-format`) - Shell script formatting

### Markdown

- **Markdown Preview GitHub Styles** (`bierner.markdown-preview-github-styles`) - GitHub-styled markdown preview
- **Markdown Mermaid** (`bierner.markdown-mermaid`) - Mermaid diagram support

### Utilities

- **Render CRLF** (`medo64.render-crlf`) - Line ending visualization

## Volume Management

The container uses a named volume for `node_modules` to improve performance by preventing file system synchronization of dependency files between the host and container.
