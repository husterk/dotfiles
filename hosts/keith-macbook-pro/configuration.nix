# Host-specific configuration for 'keith-macbook-pro'.
{ pkgs, ... }:

let
  vars = builtins.fromTOML (builtins.readFile ./host-vars.toml);
  manifest = builtins.fromTOML (builtins.readFile ./host-manifest.toml);
  repoRoot = ../..;
  modulePaths = manifest.system.modules ++ builtins.concatMap (app: app.modules or [ ]) manifest.apps;
in
{
  # Manifest paths are repo-root relative and start with "/".
  imports = map (path: repoRoot + path) modulePaths;

  system = {
    # Required by darwin modules that act for a user, including homebrew.
    primaryUser = vars.USER_USERNAME;

    # Used for backwards compatibility. Set to the version when first installing.
    # See: darwin-rebuild changelog
    stateVersion = 6;

    activationScripts.extraActivation.text = ''
      # shellcheck disable=SC1091
      source ${../../scripts/script-helpers.sh}
      export -f script_header script_footer log_info log_success log_warning log_error
      export RED GREEN YELLOW BLUE CYAN BOLD NC

      ${pkgs.bash}/bin/bash ${./scripts}/create-additional-symlinks.sh \
        "${vars.USER_USERNAME}"
      ${pkgs.bash}/bin/bash ${./scripts}/install-yazi-plugins.sh \
        "${vars.USER_USERNAME}" \
        "${pkgs.yazi}/bin/ya"
      ${pkgs.bash}/bin/bash ${./scripts}/set-login-shell.sh \
        "${vars.USER_USERNAME}"
      ${pkgs.bash}/bin/bash ${./scripts}/configure-dock.sh \
        "${vars.PATH_USERS}" \
        "${vars.USER_USERNAME}" \
        "${pkgs.dockutil}/bin/dockutil"
    '';
  };

  networking = {
    hostName = "keith-macbook-pro";
    computerName = "Keith's MacBook Pro";
  };
}
