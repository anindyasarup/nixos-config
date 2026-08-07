{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
    pnpm
    osv-scanner
    git-credential-manager
    gh
    fd
    ripgrep
    tree

    discord
    google-chrome
    raycast
    whatsapp-for-mac
    zoom-us
    jetbrains-toolbox
  ];
}
