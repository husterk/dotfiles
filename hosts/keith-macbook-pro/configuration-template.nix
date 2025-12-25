# Host-specific configuration for 'keith-macbook-pro'.
# This file is imported by the associated flake.nix.
{ config, pkgs, inputs, ... }:

{
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

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    # TODO - Add host-specific packages here.
  ];

  # =========================================================================
  # User Configuration
  # =========================================================================
  
  # Uncomment and configure for your user
  # users.users.myusername = {
  #   name = "myusername";
  #   home = "/Users/myusername";
  #   shell = pkgs.zsh;
  # };

  # Set Nushell as the default terminal shell for your user.
  users.users.${USER_USERNAME} = {
    shell = pkgs.nushell;
  };

  # =========================================================================
  # Host-specific macOS Settings
  # =========================================================================
  
  # Override or extend common system defaults
  # system.defaults = {
  #   dock = {
  #     tilesize = 48;
  #     # Add host-specific dock settings
  #   };
    
  #   # Add more host-specific defaults
  # };

  # Set the system primary user, required for some darwin modules
  # including homebrew.
  system.primaryUser = "${USER_USERNAME}";

  # Used for backwards compatibility. Set to the version when first installing.
  # See: darwin-rebuild changelog
  system.stateVersion = 6;
}
