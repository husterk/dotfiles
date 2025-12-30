{
  description = "Development environment for dotfiles management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true; # Required for 1Password CLI
        };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "dotfiles-dev";

          # Development dependencies
          buildInputs = with pkgs; [
            # === REQUIRED: Core utilities ===
            git # Version control (repo management)
            gnused # GNU sed (used extensively in bootstrap scripts for text processing)
            gettext # Provides envsubst (used for variable substitution in templates)
            bash # Modern bash 4+ (required for globstar support in scripts)

            # === REQUIRED: Task runner ===
            go-task # Modern task runner - executes all Taskfile commands

            # === REQUIRED: Script dependencies ===
            yq-go # YAML processor (parses host-manifest.yml in all task scripts)
            _1password-cli # 1Password CLI (retrieves secrets for .env generation)

            # === REQUIRED: Shell script quality tools ===
            shellcheck # Linter for shell scripts (task dev:lint)
            shfmt # Formatter for shell scripts (task dev:format)

            # === OPTIONAL: Nix development tools ===
            # Only needed when editing Nix configuration files
            nil # Nix Language Server Protocol (editor support)
            nixpkgs-fmt # Nix code formatter
            statix # Nix linter (static analysis)

            # === OPTIONAL: Editor with LSPs ===
            # Pre-configured editor with language servers for convenience
            neovim # Text editor
            nodePackages.bash-language-server # Bash LSP (shell script editing)
            lua-language-server # Lua LSP (Neovim config editing)
            marksman # Markdown LSP (documentation editing)
          ];

          # Shell initialization
          # External script at: .nix-shell/scripts/shell-hook.sh
          # Kept inline for Nix evaluation, but maintained as separate file for shellcheck
          shellHook = builtins.readFile ./scripts/shell-hook.sh;
        };
      }
    );
}
