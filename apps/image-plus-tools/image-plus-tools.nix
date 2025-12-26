{ config, pkgs, ... }:

{
  # =========================================================================
  # Mac AppStore Applications via 'mas', managed through Homebrew
  # - Must be manually uninstalled from the App Store if removed from this list.
  # =========================================================================

  homebrew = {
    masApps = {
      "Image Tool+" = 1524216218;
    };
  };
}
