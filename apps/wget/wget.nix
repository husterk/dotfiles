{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    wget
  ];

  # =========================================================================
  # Environment Variables
  # =========================================================================

  environment.variables = {
    # Tell wget where to find the user configuration file.
    WGETRC = "$HOME/.config/wgetrc";
  };
}
