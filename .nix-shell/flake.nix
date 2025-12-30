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
            # Core tools
            git
            gnused
            gettext # for envsubst
            bash # Modern bash (4+) for globstar support

            # Script dependencies
            yq-go # YAML processor
            _1password-cli # 1Password CLI

            # Shell scripting tools
            shellcheck
            shfmt

            # Nix development
            nil # Nix LSP
            nixpkgs-fmt
            statix # Nix linter

            # Editor with LSPs
            neovim
            nodePackages.bash-language-server
            lua-language-server
            marksman # Markdown LSP

            # Additional utilities
            curl
            wget
            tree
            jq
          ];

          # Shell initialization
          shellHook = ''
            echo "🚀 Dotfiles development environment loaded"
            echo ""
            echo "Available tools:"
            echo "  • yq:         $(yq --version)"
            echo "  • 1Password:  $(op --version 2>/dev/null || echo 'not authenticated')"
            echo "  • Neovim:     $(nvim --version | head -n1)"
            echo ""

            # Ensure 1Password CLI is authenticated
            if ! op account list &> /dev/null; then
              echo "⚠️  Warning: 1Password CLI not authenticated"
              echo "   Run: eval \$(op signin)"
              echo ""
            else
              # Auto-generate .env from template if it doesn't exist or template is newer
              if [ -f .nix-shell/.env.template ]; then
                if [ ! -f .env ] || [ .nix-shell/.env.template -nt .env ]; then
                  echo "📝 Generating .env from 1Password..."
                  if op inject -i .nix-shell/.env.template -o .env &>/dev/null; then
                    echo "✅ Generated .env file"
                  else
                    echo "⚠️  Failed to generate .env (check 1Password vault access)"
                  fi
                  echo ""
                fi
              fi
            fi

            # Set up environment
            export DOTFILES_ROOT="$PWD"
            export PATH="$DOTFILES_ROOT:$PATH"

            # Load .env file if it exists
            if [ -f .env ]; then
              echo "📄 Loading environment from .env"
              set -a
              source .env
              set +a
            fi

            echo "Commands:"
            echo "  ./dotfiles --help    # Show available commands"
            echo "  nvim                 # Open Neovim with LSPs"
            echo ""
          '';
        };
      }
    );
}
