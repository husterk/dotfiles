{ pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment = {
    systemPackages = with pkgs; [
      nushell
    ];

    # Register it as a valid shell
    shells = [ pkgs.nushell ];

    # =========================================================================
    # Environment Variables for Nushell
    # =========================================================================

    # These environment variables are set system-wide and will be available
    # when nushell starts as a login shell
    variables = {
      # Set NIX_PROFILES so nushell can find Nix packages
      NIX_PROFILES = "/nix/var/nix/profiles/default /run/current-system/sw";
    };

    # Ensure nix-darwin system paths are in the system PATH
    systemPath = [
      "/run/current-system/sw/bin"
    ];
  };
}
