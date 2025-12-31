{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    neovim
    nodejs_24 # Required for GitHub Copilot integration
    statix # Static analyzer for nix files
  ];
}
