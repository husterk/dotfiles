_:

{
  # =========================================================================
  # Enable Homebrew management
  # =========================================================================

  homebrew = {
    casks = [
      "visual-studio-code"
    ];
  };

  # =========================================================================
  # Default editor
  # =========================================================================

  # --wait blocks until the buffer is closed, which is what git, mise, and
  # other tools that shell out to $EDITOR expect.
  environment.variables = {
    EDITOR = "code --wait";
  };
}
