{
  description = "Declarative macOS config (nix-darwin + home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    vars = {
      url = "path:./vars-required.nix";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      vars,
    }:
    let
      varsValue = import vars;
      inherit (varsValue) system username;
      pkgs = import nixpkgs { inherit system; };
      moduleArgs = {
        vars = varsValue;
      };

      mkDarwin =
        profileModules:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = moduleArgs;
          modules = [
            ./modules/darwin.nix
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
                users.${username} = import ./modules/home;
              };
            }
          ]
          ++ profileModules;
        };

    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.statix
          pkgs.just
          pkgs.uv
        ];
      };

      darwinConfigurations = {
        personal = mkDarwin [ ];
        work = mkDarwin [ ./modules/work.nix ];
      };
    };
}
