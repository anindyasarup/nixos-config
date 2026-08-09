{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    postman
    slack
    colima
    docker
    github-copilot-cli
  ];
}
