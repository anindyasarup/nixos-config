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
    whatsapp-for-mac
    zoom-us
    jetbrains-toolbox
    brave
  ];
}
