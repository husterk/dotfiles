# macOS-specific configuration module
# Import this module in macOS host configurations
_:

{
  # =========================================================================
  # System Environment Variables
  # =========================================================================

  environment.variables = {
    # Set up XDG base directories for modern application configuration.
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_CACHE_HOME = "$HOME/Library/Caches";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
  };

  # nix-darwin's environment.variables only writes /etc/zshenv, so GUI apps
  # spawned by launchd (Finder/Dock/Spotlight, GUI editors, etc.) don't see
  # these XDG vars. A user LaunchAgent runs at login to push them into
  # launchd's env so any app launchd later spawns inherits them.
  launchd.user.agents.xdg-env = {
    serviceConfig = {
      Label = "com.user.xdg-env";
      RunAtLoad = true;
      KeepAlive = false;
      ProgramArguments = [
        "/bin/sh"
        "-c"
        ''
          /bin/launchctl setenv XDG_CONFIG_HOME "$HOME/.config"
          /bin/launchctl setenv XDG_CACHE_HOME "$HOME/Library/Caches"
          /bin/launchctl setenv XDG_DATA_HOME "$HOME/.local/share"
          /bin/launchctl setenv XDG_STATE_HOME "$HOME/.local/state"
        ''
      ];
    };
  };

  # =========================================================================
  # macOS System Defaults
  # =========================================================================

  system.defaults = {
    # -------------------------------------------------------------------------
    # Finder: High-visibility for dotfiles and file extensions
    # -------------------------------------------------------------------------
    finder = {
      AppleShowAllExtensions = true; # Always show .sh, .nu, .json.
      AppleShowAllFiles = true; # See your .config and .ssh folders.
      FXEnableExtensionChangeWarning = false; # Don't nag when renaming files.
      _FXShowPosixPathInTitle = true; # Show full path in Finder title bar.
      ShowPathbar = true; # Show path bar at bottom of Finder windows.
      ShowStatusBar = true; # Show status bar at bottom of Finder windows.
      QuitMenuItem = true; # Allow quitting Finder (Cmd+Q).
    };

    # -------------------------------------------------------------------------
    # Dock: Minimalist and fast
    # -------------------------------------------------------------------------
    dock = {
      autohide = true; # Auto-hide the dock to save screen space.
      autohide-delay = 0.0; # No delay when showing the dock.
      autohide-time-modifier = 0.2; # Fast animation when showing/hiding.
      orientation = "bottom"; # Keep the dock at the bottom of the screen.
      show-recents = false; # Keep the dock clean of "suggested" apps.
      static-only = false; # Must be set to false to allow dockutil to modify the dock.
      mru-spaces = false; # Stop macOS from rearranging your Spaces.
    };

    # -------------------------------------------------------------------------
    # Global System Settings
    # -------------------------------------------------------------------------
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # Use Dark Mode throughout macOS.
      AppleShowAllExtensions = true; # Show all file extensions in Finder.
      ApplePressAndHoldEnabled = false; # Disable accent popup so keys repeat.
      InitialKeyRepeat = 15; # 150ms delay.
      KeyRepeat = 2; # 30ms repeat rate.
      "com.apple.swipescrolldirection" = true; # "Natural" scrolling enabled.
    };
  };

  # =========================================================================
  # macOS Keyboard Configuration
  # =========================================================================

  system.keyboard = {
    enableKeyMapping = true; # Enable custom key mappings.
    remapCapsLockToControl = false; # Don't remap Caps Lock.
  };

  # =========================================================================
  # PAM Configuration - Touch ID for sudo
  # =========================================================================

  security.pam.services.sudo_local.touchIdAuth = true;
}
