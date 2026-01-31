{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    neovim
    nodejs_24 # Required for GitHub Copilot integration
    nixd # Nix language server
    nixfmt # Nix formatter (RFC style)
    statix # Static analyzer for nix files
    treefmt # Universal code formatter
  ];
}
