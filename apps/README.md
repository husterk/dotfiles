# Apps

This directory contains application-specific Nix modules and their corresponding dotfiles (configuration files). Each subdirectory represents a single application or tool that can be included in a host's configuration.

## Structure

Each app directory follows this pattern:

```
apps/<app-name>/
├── <app-name>.nix     # Nix module that installs the app and sets environment variables
└── <dotfiles>         # Configuration files (e.g., .zshrc, config.nu, .curlrc)
```

## Adding a New App

1. **Create the app directory**:

    ```bash
    mkdir -p apps/<app-name>
    ```

2. **Create the Nix module** (`<app-name>.nix`):

    ```nix
    { config, pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        <package-name>
      ];

      # Optional: Add environment variables
      environment.variables = {
        VAR_NAME = "value";
      };
    }
    ```

3. **Add configuration files** (dotfiles):
    - Place any dotfiles directly in the app directory
    - These will be deployed to `$HOME` using GNU Stow
    - Use appropriate subdirectories for XDG Base Directory structure (e.g., `.config/<app>`)

4. **Register the app** in your host's `host-manifest.yml`:

    ```yaml
    apps:
        - name: example-app
            modules:
            - /apps/example-app/example-app.nix
            dotfiles:
            - source: /apps/example-app/config.json
                target: ~/.config/example-app/config.json
    ```

5. **Apply the app** to your host:
    1. Regenerate the nix configuration.
    2. Regenerate dotfiles.
    3. Apply the nix configuration.
    4. Deploy dotfiles.

## Updating an Existing App

1. Modify the `.nix` file or dotfiles as needed.
2. Regenerate the nix configuration.
3. Regenerate dotfiles.
4. Apply the nix configuration.
5. Deploy dotfiles.

## Available Apps

| App                  | Description                                          | Installs Via | Has Dotfiles |
| -------------------- | ---------------------------------------------------- | ------------ | ------------ |
| `1password`          | Password manager and CLI tool                        | Homebrew     | Yes          |
| `curl`               | Command-line tool for transferring data with URLs    | Nix          | Yes          |
| `dropbox`            | File hosting and synchronization service             | Homebrew     | No           |
| `git`                | Distributed version control system                   | Nix          | Yes          |
| `homebrew`           | Package manager for macOS                            | N/A (Native) | No           |
| `inetutils`          | Network utilities (telnet, ftp, etc.)                | Nix          | No           |
| `iterm2`             | macOS terminal emulator                              | Homebrew     | Yes          |
| `nix`                | Nix package manager configuration                    | N/A (Native) | Yes          |
| `nss`                | Network Security Services libraries                  | Nix          | No           |
| `nushell`            | Modern shell with structured data support            | Nix          | Yes          |
| `orbstack`           | Fast, light, and simple container & Linux VM manager | Homebrew     | Yes          |
| `stow`               | GNU Stow symlink farm manager                        | Nix          | No           |
| `swaks`              | Swiss Army Knife SMTP testing tool                   | Nix          | No           |
| `visual-studio-code` | Code editor and IDE                                  | Homebrew     | No           |
| `wget`               | Network downloader                                   | Nix          | Yes          |
| `zsh`                | Z Shell with Oh My Zsh framework                     | Nix          | Yes          |

## Notes

- **Nix packages** are installed via `nixpkgs` and are more reproducible
- **Homebrew packages** are used when the app is not available or suitable in `nixpkgs` (e.g., GUI applications)
- **Dotfiles** are deployed using GNU Stow, which creates symlinks from `$HOME` to the generated dotfiles directory
- **Environment variables** defined in `.nix` files are set system-wide via nix-darwin
