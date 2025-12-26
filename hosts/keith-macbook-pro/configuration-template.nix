# Host-specific configuration for 'keith-macbook-pro'.
# This file is imported by the associated flake.nix.
{ config, pkgs, inputs, ... }:

{
  # Set the system primary user, required for some darwin modules
  # including homebrew.
  system.primaryUser = "${USER_USERNAME}";

  # Used for backwards compatibility. Set to the version when first installing.
  # See: darwin-rebuild changelog
  system.stateVersion = 6;

  # Import all required modules.
  imports = [
    # Modules
    {{MANIFEST_SYSTEM_MODULES}}
    # Apps
    {{MANIFEST_APPS_MODULES}}
  ];

  # =========================================================================
  # Host-specific Settings
  # =========================================================================
  
  networking.hostName = "keith-macbook-pro";
  networking.computerName = "Keith's MacBook Pro";

  # =========================================================================
  # User Configuration
  # =========================================================================

  # Run the "extraActivation" script to perform additional, custom configuration
  # steps such as setting the login shell, customizing the dock, etc.
  system.activationScripts.extraActivation.text = ''
    # Source script-helpers.sh from .devcontainer/scripts and export functions
    # shellcheck disable=SC1091
    source ${../../.devcontainer/scripts/script-helpers.sh}
    export -f script_header script_footer log_info log_success log_warning log_error
    export RED GREEN YELLOW BLUE CYAN BOLD NC

    ${pkgs.bash}/bin/bash ${./scripts}/create-additional-symlinks.sh \
      "${USER_USERNAME}"
    ${pkgs.bash}/bin/bash ${./scripts}/set-login-shell.sh \
      "${USER_USERNAME}"
    ${pkgs.bash}/bin/bash ${./scripts}/configure-dock.sh \
      "${PATH_USERS}" \
      "${USER_USERNAME}" \
      "${pkgs.dockutil}/bin/dockutil"
  '';

  # =========================================================================
  # Host-specific macOS Settings
  # =========================================================================
}
