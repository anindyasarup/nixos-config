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
    harness-config.url = "github:anindyasarup/harness-config";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vars = {
      url = "path:./vars-required.nix";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      nix-darwin,
      home-manager,
      nix-homebrew,
      harness-config,
      git-hooks,
      vars,
      ...
    }:
    let
      varsValue = import vars;
      inherit (varsValue) system username;
      pkgs = import nixpkgs { inherit system; };
      moduleArgs = {
        vars = varsValue;
      };

      mkDarwin = import ./modules/mk-darwin.nix { inherit nix-darwin home-manager nix-homebrew; } {
        inherit system username moduleArgs;
      };

      harness = {
        home-manager.sharedModules = [
          harness-config.homeModules.default
          {
            harness.claude-code.enable = true;
            harness.omp.enable = true;
          }
        ];
      };

      preCommit = git-hooks.lib.${system}.run {
        src = ./.;
        package = pkgs.prek;
        hooks = {
          betterleaks = {
            enable = true;
            name = "betterleaks";
            package = pkgs.betterleaks;
            entry = "${pkgs.betterleaks}/bin/betterleaks git --pre-commit --staged";
            pass_filenames = false;
            priority = 1;
          };
          statix = {
            enable = true;
            priority = 1;
          };
          deadnix = {
            enable = true;
            priority = 1;
          };
          nixfmt = {
            enable = true;
            priority = 0;
          };
        };
      };
    in
    {
      formatter.${system} = pkgs.nixfmt-tree;
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = [
          pkgs.just
          pkgs.uv
        ]
        ++ preCommit.enabledPackages;
        inherit (preCommit) shellHook;
      };

      darwinConfigurations = {
        personal = mkDarwin [ harness ];
        work = mkDarwin [
          harness
          ./modules/work.nix
        ];
      };
    };
}
