# Base configuration module
# This module must be imported by all host configurations
_:

{
  # =========================================================================
  # Nix Configuration (Common to all hosts)
  # =========================================================================

  # nix-darwin now manages nix-daemon unconditionally when nix.enable is on
  # services.nix-daemon.enable is deprecated and removed

  nix = {
    settings = {
      # Enable flakes and new nix command
      experimental-features = "nix-command flakes";

      # Build settings
      max-jobs = 8;
      cores = 4;

      # Trusted users
      trusted-users = [ "@admin" ];
    };

    # Automatically optimize the Nix store (use nix.optimise.automatic instead of auto-optimise-store)
    optimise = {
      automatic = true;
    };

    # Garbage collection
    gc = {
      automatic = true;
      interval = {
        Weekday = 7;
      }; # Run on Sundays
      options = "--delete-older-than 30d";
    };
  };

  # =========================================================================
  # nixpkgs Configuration
  # =========================================================================

  nixpkgs.config = {
    allowUnfree = true;
  };
}
