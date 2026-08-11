{
  pkgs,
  vars,
  ...
}:

{
  imports = [
    ./system-defaults.nix
    ./homebrew.nix
    ./nix-gc.nix
  ];

  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  users.users.${vars.username}.home = vars.homeDirectory;
  system.primaryUser = vars.username;

  programs.zsh.enable = true;

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  security = {
    pki.certificateFiles = vars.certificateFiles or [ ];
    pam.services.sudo_local = {
      touchIdAuth = true;
      reattach = false;
    };
  };

  system.stateVersion = 6;
}
