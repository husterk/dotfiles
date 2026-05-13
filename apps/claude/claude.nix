{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  # jq is needed by ~/.claude/statusline.sh, which runs in a non-interactive
  # shell where mise's jq is not on PATH.
  environment.systemPackages = with pkgs; [
    jq
  ];

  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  homebrew = {
    casks = [
      "claude"
      "claude-code"
    ];
  };
}
