{ config, pkgs, ... }:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  # agent-of-empires (aoe): Rust TUI session manager for Claude Code and other
  # AI coding agents. Installed via Homebrew formula (not cask) since it's CLI.
  # Pulls in tmux + openssl@3 as Homebrew dependencies.
  homebrew = {
    brews = [
      "aoe"
    ];
  };
}
