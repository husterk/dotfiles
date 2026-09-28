{ pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    lazygit
    delta # Syntax highlighting pager for lazygit
  ];
}
