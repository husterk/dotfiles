{ pkgs, ... }:

{
  # =========================================================================
  # System Environment Variables
  # =========================================================================

  environment.variables = {
    # Ensure the terminal always knows to use 1Password for SSH.
    SSH_AUTH_SOCK = "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  };

  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    _1password-gui
    _1password-cli
  ];
}
