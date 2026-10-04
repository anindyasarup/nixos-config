{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    slack
    colima
    docker
    github-copilot-cli
  ];
}
