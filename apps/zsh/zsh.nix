{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    zsh
    oh-my-zsh
  ];

  # =========================================================================
  # Environment Variables for Zsh
  # =========================================================================

  environment.variables = {
    # Tell Zsh where to find its config (NAME IS CRUCIAL).
    ZDOTDIR = "$HOME/.config/zsh";
    # Path to Oh My Zsh installation (NAME IS CRUCIAL).
    ZSH = "${pkgs.oh-my-zsh}/share/oh-my-zsh";
  };

  # =========================================================================
  # Zsh Program Configuration
  # =========================================================================

  programs.zsh.enable = true;
}
