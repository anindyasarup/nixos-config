{
  nix-darwin,
  home-manager,
  nix-homebrew,
}:
{
  system,
  username,
  moduleArgs,
}:
profileModules:
nix-darwin.lib.darwinSystem {
  inherit system;
  specialArgs = moduleArgs;
  modules = [
    ./darwin.nix
    nix-homebrew.darwinModules.nix-homebrew
    {
      nix-homebrew = {
        enable = true;
        user = username;
      };
    }
    home-manager.darwinModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = moduleArgs;
        backupFileExtension = "backup";
        users.${username} = import ./home;
      };
    }
  ]
  ++ profileModules;
}
