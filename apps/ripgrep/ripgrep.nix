{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    ripgrep
  ];

  # =========================================================================
  # Environment Variables for ripgrep
  # =========================================================================

  environment.variables = {
    # Tells ripgrep where to find its config file.
    RIPGREP_CONFIG_PATH = "$HOME/.config/ripgrep/config";
  };
}
