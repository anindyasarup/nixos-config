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
        import ./modules/mk-darwin.nix { inherit nix-darwin home-manager nix-homebrew; }
          { inherit system username moduleArgs; };

      lefthookConfig = (pkgs.formats.yaml { }).generate "lefthook.yml" {
        pre-commit.commands.betterleaks.run = "betterleaks git --pre-commit --staged";
      };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.statix
          pkgs.just
          pkgs.uv
          pkgs.lefthook
          pkgs.betterleaks
        ];
        shellHook = ''
          ln -sf ${lefthookConfig} lefthook.yml
          lefthook install
        '';
      };

      darwinConfigurations = {
        personal = mkDarwin [ ];
        work = mkDarwin [ ./modules/work.nix ];
      };
    };
}
