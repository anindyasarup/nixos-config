{
  vars,
  ...
}:

{
  programs = {
    zsh.enable = true;

    bash.enable = true;

    starship.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config.global.hide_env_diff = true;
      stdlib = ''
        : "''${XDG_CACHE_HOME:=$HOME/.cache}"
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
          echo "''${direnv_layout_dirs[$PWD]:=$(
            echo -n "$XDG_CACHE_HOME"/direnv/layouts/
            echo -n "$PWD" | shasum | cut -d ' ' -f 1
          )}"
        }
      '';
    };
  };

  home = {
    shellAliases = {
      zed = "zeditor";
    };

    sessionPath = [
      "$HOME/.local/bin"
      "$HOME/Library/pnpm"
    ];
    sessionVariables.PNPM_HOME = "${vars.homeDirectory}/Library/pnpm";
  };
}
