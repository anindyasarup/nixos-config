{
  pkgs,
  ...
}:

{
  programs = {
    fzf = {
      enable = true;
      defaultOptions = [
        "--height=60%"
        "--layout=reverse"
        "--border"
      ];
      fileWidget = {
        command = "${pkgs.fd}/bin/fd --type f";
        options = [
          "--preview '${pkgs.bat}/bin/bat --style=numbers --color=always --line-range=:500 {}'"
        ];
      };
      changeDirWidget = {
        command = "${pkgs.fd}/bin/fd --type d";
        options = [ "--preview '${pkgs.tree}/bin/tree -C {} | head -200'" ];
      };
    };

    bat.enable = true;

    yazi.enable = true;

    btop.enable = true;
  };
}
