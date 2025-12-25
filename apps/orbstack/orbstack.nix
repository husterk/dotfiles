{ config, pkgs, ... }:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  homebrew = {
    casks = [
      "orbstack"
    ];
  };

  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    docker
  ];

  # =========================================================================
  # Environment Variables
  # =========================================================================

  environment.variables = {
    # Tell docker where to find the user configuration file.
    DOCKER_CONFIG = "$HOME/.config/docker";
  };
}
