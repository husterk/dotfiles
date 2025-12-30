{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    lazygit
  ];

  # =========================================================================
  # Environment Variables for lazygit
  # =========================================================================

  environment.variables = {
    CONFIG_DIR = "$HOME/.config/lazygit";
  };
}
