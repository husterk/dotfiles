{ pkgs, ... }:

{
  # Formatters and linters the repo's own checks call (treefmt, dev:lint).
  # CI installs the same packages from the nixpkgs revision flake.lock pins.
  environment.systemPackages = with pkgs; [
    nixfmt # Nix formatter (RFC style)
    statix # Static analyzer for nix files
    treefmt # Universal code formatter
  ];
}
