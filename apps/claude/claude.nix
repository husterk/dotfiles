{ pkgs, ... }:

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
      # The plain claude-code cask tracks the stable channel and conflicts
      # with this one. The release channel comes from the cask name, not from
      # autoUpdatesChannel in settings.json.
      "claude-code@latest"
    ];
  };
}
