{ config, pkgs, ... }:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  # agent-of-empires (aoe): Rust TUI session manager for Claude Code and other
  # AI coding agents. Installed via Homebrew formula (not cask) since it's CLI.
  # tmux is declared explicitly (rather than relying on aoe's transitive dep)
  # so AoE workflows don't break silently if aoe's formula ever drops it.
  homebrew = {
    brews = [
      "aoe"
      "tmux"
    ];
  };
}
