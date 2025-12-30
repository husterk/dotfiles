{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    zsh
  ];

  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  homebrew = {
    brews = [
      "zsh-syntax-highlighting"
      "zsh-autosuggestions"
    ];
  };

  # =========================================================================
  # Environment Variables for Zsh
  # =========================================================================

  environment.variables = {
    # Tell Zsh where to find its config (NAME IS CRUCIAL).
    ZDOTDIR = "$HOME/.config/zsh";
    ZSH_HISTORY_DIR = "$HOME/.local/share/zsh"; # Directory for Zsh history files.
    HISTFILE = "$HOME/.local/share/zsh/history"; # Note: Must be named HISTFILE for Zsh.
  };

  # =========================================================================
  # Zsh Program Configuration
  # =========================================================================

  programs.zsh.enable = true;
}
