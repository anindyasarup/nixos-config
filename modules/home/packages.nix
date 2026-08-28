{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
    pi-coding-agent
    osv-scanner
    gh
    fd
    ripgrep
    tree

    bruno
    discord
    raycast
    zoom-us
    brave
    jetbrains.datagrip
  ];
}
