{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
    osv-scanner
    gh
    fd
    ripgrep
    tree

    discord
    raycast
    zoom-us
    brave
    jetbrains.datagrip
  ];
}
