{ pkgs, ... }:

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
    # Zsh reads its config from ZDOTDIR; the variable name is fixed by zsh.
    ZDOTDIR = "$HOME/.config/zsh";
    ZSH_HISTORY_DIR = "$HOME/.local/share/zsh"; # Directory for Zsh history files.
    HISTFILE = "$HOME/.local/share/zsh/history"; # Note: Must be named HISTFILE for Zsh.
  };

  # =========================================================================
  # Zsh Program Configuration
  # =========================================================================

  programs.zsh.enable = true;
}
