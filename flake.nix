{
  description = "nix-darwin configurations, one per directory under hosts/";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Private Homebrew casks. The stub keeps the public repo buildable; the
    # owner's apply task overrides this input with a local private clone.
    private = {
      url = "path:./nix/private-stub";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      private,
      ...
    }:
    let
      hosts = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs hosts (
        host:
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${host}/configuration.nix
            "${private}/default.nix"
          ];
        }
      );
    };
}
