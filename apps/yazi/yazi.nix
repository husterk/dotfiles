{ config, pkgs, ... }:

{
  # =========================================================================
  # System Environment Variables
  # =========================================================================

  environment.variables = {
    # Ensures Yazi knows it's inside a high-end terminal.
    # This allows for proper previewing of images, videos, etc.
    TERM = "xterm-256color";
  };


  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    yazi
    ffmpegthumbnailer # For video thumbnail previews
    poppler-utils # For PDF thumbnail previews
    imagemagick # For image thumbnail previews
  ];
}
