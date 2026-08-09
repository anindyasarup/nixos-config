{ vars, ... }:

{
  homebrew.casks = [
  ];

  home-manager.users.${vars.username}.imports = [ ./home/work.nix ];
}
