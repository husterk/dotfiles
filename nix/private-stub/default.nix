# Loaded only when the private overlay is absent. Homebrew's zap would
# uninstall undeclared private casks and trash their data, so turn it off.
{ lib, ... }:
{
  homebrew.onActivation.cleanup = lib.mkForce "none";
}
