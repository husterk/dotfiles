_:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  # 1. Enable Homebrew management
  homebrew = {
    enable = true; # Enable Homebrew package management.
    onActivation = {
      cleanup = "zap"; # Removes anything not listed here (keep 'brew list' clean!).
      autoUpdate = true; # Auto-update Homebrew on activation.
      upgrade = true; # Auto-upgrade installed packages on activation.
    };
  };
}
