{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    claude-code
    pi-coding-agent
    omp
    osv-scanner
    gh
    fd
    ripgrep
    tree
    bruno-cli

    # Applications
    bruno
    discord
    raycast
    zoom-us
    jetbrains.datagrip
  ];
}
