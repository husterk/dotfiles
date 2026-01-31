{ config, pkgs, ... }:

{
  # =========================================================================
  # Text Processing Utilities
  # =========================================================================
  # Provides envsubst command for environment variable substitution in templates
  # Used by bootstrap scripts to generate configuration files

  environment.systemPackages = with pkgs; [
    gettext
  ];
}
