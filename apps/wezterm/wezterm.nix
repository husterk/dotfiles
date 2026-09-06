{ config, pkgs, ... }:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  # The upstream `wezterm` cask is unmaintained (pinned to the 2024-02-03
  # release); wezterm.org now points macOS users at the nightly cask.
  # `greedy = true` is required because the cask is `version :latest`, which
  # plain `brew upgrade` skips.
  homebrew = {
    casks = [
      {
        name = "wezterm@nightly";
        greedy = true;
      }
    ];
  };

  # =========================================================================
  # Required System Fonts
  # =========================================================================

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono # Matches the name in your wezterm.lua
  ];
}
