{
  nixConfig = {
    extra-substituters = [
      "https://devenv.cachix.org/"
      "https://niri.cachix.org"
    ];
    extra-trusted-public-keys = [
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.follows = "nixpkgs";
    nixpkgs-unstable.follows = "nixpkgs";

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    claude-code.url = "github:sadjow/claude-code-nix";
    codex-cli.url = "github:sadjow/codex-cli-nix";
    pi.url = "github:lukasl-dev/pi.nix";
    pi.inputs.nixpkgs.follows = "nixpkgs";

    devenv.url = "github:cachix/devenv";
    git-hooks.url = "github:cachix/git-hooks.nix";

    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";

    dank-material-shell.url = "github:AvengeMedia/DankMaterialShell";
    dank-material-shell.inputs.nixpkgs.follows = "nixpkgs";

    systems-linux.url = "github:nix-systems/default-linux";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.flake-utils.inputs.systems.follows = "systems-linux";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;

      overlays = {
        default = import ./overlays;
        darwin = import ./overlays/darwin.nix;
      };

      mkSystem = import ./lib/mkSystem.nix { inherit inputs overlays; };
      machines = import ./machines { inherit inputs mkSystem; };
    in
    {
      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);

      devShells = forEachSystem (system: {
        default = inputs.devenv.lib.mkShell {
          inherit inputs;
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            {
              git-hooks.hooks = {
                nixfmt.enable = true;
              };
              cachix.pull = [ "devenv" ];
            }
          ];
        };
      });

      inherit (machines) nixosConfigurations darwinConfigurations;

      apps.aarch64-darwin.utm-install = {
        type = "app";
        program = "${
          nixpkgs.legacyPackages.aarch64-darwin.callPackage ./pkgs/utm-install { }
        }/bin/utm-install";
      };
    };
}
