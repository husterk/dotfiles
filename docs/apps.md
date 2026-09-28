# Apps

`apps/` holds one directory per application or tool. Each directory has a
nix-darwin module that installs the app, and optionally the dotfiles that
configure it. A host includes an app by listing it in its
`hosts/<host>/host-manifest.toml`.

## Structure

```text
apps/<app-name>/
├── <app-name>.nix   # nix-darwin module: packages, casks, environment variables
└── dotfiles/        # optional: templates rendered into generated/ and stowed into $HOME
```

Templates may use `${VAR}` placeholders for values in
`hosts/<host>/host-vars.toml`. `mise run dotfiles:generate` substitutes them.

## Adding an app

The `add-app` Claude Code skill does these steps; by hand:

1. Create `apps/<app-name>/<app-name>.nix`:

    ```nix
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [ <package-name> ];
      # GUI apps come from Homebrew instead:
      # homebrew.casks = [ "<cask-name>" ];
    }
    ```

    A module that takes no arguments is written `_: { ... }`.

2. Optionally add templates under `apps/<app-name>/dotfiles/`.

3. Register the app in `hosts/<host>/host-manifest.toml`. Edit it as text and
   keep the keys sorted, which is how taplo formats it:

    ```toml
    [[apps]]
    modules = ["/apps/example-app/example-app.nix"]
    name = "example-app"
    [[apps.dotfiles]]
    source = "/apps/example-app/dotfiles/**/*"
    target = "~/.config/example-app/"
    ```

    A glob `source` needs a `target` directory ending in `/`.

4. Run `mise run check`, then `mise run refresh` to apply it.

Homebrew runs with `cleanup = "zap"`: removing an app's declaration
uninstalls it on the next apply. Casks that should not be published belong in
the private overlay (see the README).

## Available apps

| App                  | Description                                            | Installs via       | Dotfiles |
| -------------------- | ------------------------------------------------------ | ------------------ | -------- |
| `1password`          | Password manager and CLI                               | Nix                | Yes      |
| `agent-of-empires`   | Terminal session manager for AI coding agents          | Homebrew           | Yes      |
| `bat`                | `cat` with syntax highlighting                         | Nix                | Yes      |
| `ca-certificates`    | Mozilla CA certificate bundle                          | Homebrew           | No       |
| `claude`             | Claude desktop app and Claude Code                     | Homebrew, Nix (jq) | Yes      |
| `curl`               | Command-line tool for transferring data with URLs      | Nix                | Yes      |
| `davinci-resolve`    | Video editor                                           | App Store          | No       |
| `dockutil`           | macOS Dock management utility                          | Nix                | No       |
| `dropbox`            | File hosting and synchronization                       | Homebrew           | No       |
| `fzf`                | Command-line fuzzy finder                              | Nix                | No       |
| `gettext`            | GNU internationalization utilities (provides envsubst) | Nix                | No       |
| `gh`                 | GitHub CLI                                             | Nix                | No       |
| `git`                | Version control, with delta and SSH commit signing     | Nix                | Yes      |
| `homebrew`           | Homebrew settings (cleanup, updates)                   | Configuration only | No       |
| `image-plus-tools`   | Image format conversion utility                        | App Store          | No       |
| `inetutils`          | Network utilities (telnet, ftp, and others)            | Nix                | No       |
| `lazygit`            | Terminal UI for Git                                    | Nix                | Yes      |
| `mas`                | Mac App Store CLI                                      | Nix                | No       |
| `mise`               | Tool version manager and task runner                   | Nix                | No       |
| `neovim`             | Editor (LazyVim) and the Nix language server           | Nix                | Yes      |
| `nix`                | Nix daemon settings                                    | Configuration only | Yes      |
| `nss`                | Network Security Services libraries                    | Nix                | No       |
| `nushell`            | Shell with structured data                             | Nix                | Yes      |
| `orbstack`           | Containers and Linux VMs, plus the docker CLI          | Homebrew, Nix      | Yes      |
| `ouch`               | Archive creation and extraction CLI                    | Nix                | No       |
| `ripgrep`            | Fast recursive search                                  | Nix                | Yes      |
| `sshpass`            | Non-interactive ssh password auth                      | Nix                | No       |
| `starship`           | Shell prompt                                           | Nix                | Yes      |
| `stow`               | GNU Stow symlink farm manager                          | Nix                | No       |
| `swaks`              | SMTP testing tool                                      | Nix                | No       |
| `visual-studio-code` | Code editor                                            | Homebrew           | No       |
| `wezterm`            | Terminal emulator                                      | Homebrew           | Yes      |
| `wget`               | Network downloader                                     | Nix                | Yes      |
| `xcode`              | Apple developer tools                                  | App Store          | No       |
| `yazi`               | Terminal file manager, with preview tools              | Homebrew, Nix      | Yes      |
| `zoxide`             | Directory jumper that learns frequent paths            | Nix                | No       |
| `zsh`                | Login shell, with Homebrew-installed plugins           | Nix, Homebrew      | Yes      |

`orbstack` keeps its dotfiles in `apps/orbstack/docker/`, deployed to
`~/.config/docker/`.
