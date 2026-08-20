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
    jetbrains-toolbox
    brave
    dbeaver-bin
  ];
}
