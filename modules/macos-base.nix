# macOS-specific configuration module
# Import this module in macOS host configurations
{ config, pkgs, ... }:

{
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
  
  programs.zsh.enable = true;
}
