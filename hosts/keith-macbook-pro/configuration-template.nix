# Host-specific configuration for 'keith-macbook-pro'.
# This file is imported by the associated flake.nix.
{ config, pkgs, inputs, lib, ... }:

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

  # Set Nushell as the default login terminal shell for your user.
  # MacOS uses 'zsh' as the default shell, so we configure 'zsh' to
  # automatically launch 'nushell' when starting a new terminal session.
  programs.zsh.interactiveShellInit = ''
    # If we are in an interactive session and 'nu' is available, hand off to it.
    # Using 'exec' replaces the Zsh process with Nu, so exiting Nu closes the tab.
    if [[ -x "$(command -v nu)" && $- == *i* ]]; then
      exec nu
    fi
  '';

  # Configure the Dock using dockutil.
  # Note: The script must be named "extraActivation" to be picked up by darwin.
  # Custom script names seem to be ignored.
  # Note: Use lib.mkAfter to append to this activation script from other modules.
  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo "Configuring Dock for ${config.system.primaryUser}..."

    # Run dockutil commands as the primary user.
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --remove all "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Google Chrome.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/System/Applications/Messages.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Visual Studio Code.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Fork.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/iTerm.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/1Password.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Davinci Resolve.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Insta360 Studio.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Notes.app" "/Users/${config.system.primaryUser}"
    sudo -u "${config.system.primaryUser}" "${pkgs.dockutil}/bin/dockutil" --no-restart --add "/Applications/Stickies.app" "/Users/${config.system.primaryUser}"

    # Restart the Dock to apply changes.
    sudo -u "${config.system.primaryUser}" killall Dock

    echo "Dock configuration complete."
  '';

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
}
