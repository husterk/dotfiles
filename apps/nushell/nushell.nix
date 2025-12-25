{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    nushell
  ];

  # Register it as a valid shell
  environment.shells = [ pkgs.nushell ];
}
