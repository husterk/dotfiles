# macOS-specific configuration module
# Import this module in macOS host configurations
{ config, pkgs, ... }:

{
  # =========================================================================
  # System Environment Variables
  # =========================================================================

  environment.variables = {
    # Set up XDG base directories for modern application configuration.
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME  = "$HOME/Library/Caches";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";
  };

  # =========================================================================
  # macOS System Defaults
  # =========================================================================
  
  system.defaults = {
    # Dock settings
    # dock = {
    #   autohide = true;
    #   autohide-delay = 0.0;
    #   autohide-time-modifier = 0.2;
    #   orientation = "bottom";
    #   show-recents = false;
    #   showhidden = true;
    # };

    # Finder settings
    # finder = {
    #   AppleShowAllExtensions = true;
    #   FXEnableExtensionChangeWarning = false;
    #   FXPreferredViewStyle = "Nlsv";
    #   ShowPathbar = true;
    #   ShowStatusBar = true;
    # };

    # Global macOS settings
    # NSGlobalDomain = {
    #   AppleInterfaceStyle = "Dark";
    #   AppleShowAllExtensions = true;
      
    #   # Keyboard
    #   InitialKeyRepeat = 15;
    #   KeyRepeat = 2;
      
    #   # Disable auto-correct
    #   NSAutomaticCapitalizationEnabled = false;
    #   NSAutomaticDashSubstitutionEnabled = false;
    #   NSAutomaticPeriodSubstitutionEnabled = false;
    #   NSAutomaticQuoteSubstitutionEnabled = false;
    #   NSAutomaticSpellingCorrectionEnabled = false;
    # };

    # Trackpad settings
    # trackpad = {
    #   Clicking = true;
    #   TrackpadRightClick = true;
    # };
  };

  # =========================================================================
  # macOS Keyboard Configuration
  # =========================================================================
  
  # system.keyboard = {
  #   enableKeyMapping = true;
  #   remapCapsLockToControl = true;
  # };

  # =========================================================================
  # Common System Programs
  # =========================================================================
  
}
