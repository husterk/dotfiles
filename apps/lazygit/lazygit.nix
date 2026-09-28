{ pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    lazygit
    delta # Syntax highlighting pager for lazygit
  ];

  # =========================================================================
  # Environment Variables for lazygit
  # =========================================================================

  environment.variables = {
    CONFIG_DIR = "$HOME/.config/lazygit";
  };
}
