{ config, pkgs, ... }:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  # 1. Enable Homebrew management
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap"; # Removes anything not listed here (keep 'brew list' clean!)
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };
}
