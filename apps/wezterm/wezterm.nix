{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    wezterm
  ];

  # =========================================================================
  # Required System Fonts
  # =========================================================================

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono # Matches the name in your wezterm.lua
  ];
}
