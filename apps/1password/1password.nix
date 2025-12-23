{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    # TODO - Figure out how to install 1password-cli via nixpkgs
  ];
}
