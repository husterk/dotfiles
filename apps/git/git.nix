{ pkgs, ... }:

{
  # =========================================================================
  # Required System Packages
  # =========================================================================

  environment.systemPackages = with pkgs; [
    git
    git-credential-manager

    # core.pager and interactive.diffFilter in dotfiles/config point at delta,
    # so git is unusable without it. Also pulled in by apps/lazygit; Nix
    # deduplicates the two references.
    delta
  ];
}
