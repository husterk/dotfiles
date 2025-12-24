{ config, pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    curl
  ];

  # =========================================================================
  # Environment Variables for Curl
  # =========================================================================

  environment.variables = {
    # Tell Curl where to find its config.
    CURL_HOME = "$HOME/.config/curl";
  };
}
