# Devcontainer Scripts

This directory contains lifecycle scripts for the VS Code devcontainer.

## Scripts Overview

### initialize.sh

**When it runs:** Before container creation (on host machine)  
**Purpose:** Generates `.env` file from 1Password secrets  
**Requirements:** 1Password CLI installed and user signed in

This script:

- Validates 1Password CLI is available
- Verifies user authentication
- Generates `.env` from `.env.template` using `op inject`
- Uses colored output for clear feedback

### post-create.sh

**When it runs:** After container is created (inside container)  
**Purpose:** Configures the container environment

This script:

- Symlinks host SSH keys for passwordless host access
- Configures VS Code shell integration for zsh
- Installs Node.js packages with bun
- Uses colored output for clear feedback

### ssh-to-host.sh

**When it runs:** On-demand (when "zsh (host)" terminal is opened)  
**Purpose:** Provides SSH access from container to host machine

This script:

- Uses `HOST_USER` environment variable for dynamic username
- Connects to `host.docker.internal` with SSH
- Disables host key checking for convenience
- Provides clear error messages if misconfigured

## Design Principles

All scripts follow these conventions:

1. **Bash Standard:** All scripts use `#!/bin/bash` for consistency
2. **Color Coding:** Use color-coded log functions (log_info, log_success, log_warning, log_error)
3. **Clear Sections:** Organize with numbered steps and clear comments
4. **Error Handling:** Use `set -e` and provide helpful error messages
5. **Documentation:** Include header blocks explaining purpose and usage

## Color Coding

Scripts use ANSI color codes for output:

- **Blue** [INFO]: Informational messages
- **Green** [SUCCESS]: Successful operations
- **Yellow** [WARNING]: Non-critical issues
- **Red** [ERROR]: Critical errors requiring attention

## Maintenance

When modifying these scripts:

- Test in both host and container contexts
- Maintain the existing formatting conventions
- Update this README if adding new scripts
- Keep error messages helpful and actionable
