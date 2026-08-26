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

    discord
    raycast
    zoom-us
    brave
    jetbrains.datagrip
  ];
}
