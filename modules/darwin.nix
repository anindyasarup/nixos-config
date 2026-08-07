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

  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = false;

  system.stateVersion = 6;
}
