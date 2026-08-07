{
  config,
  lib,
  ...
}:

{
  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
    ./cli-tools.nix
    ./ghostty.nix
    ./neovim.nix
    ./zed.nix
  ];

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${config.home.homeDirectory}/Pictures/Screenshots"
  '';
}
