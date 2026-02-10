{
  nixConfig = {
    extra-substituters = [ "https://devenv.cachix.org/" ];
    extra-trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";

    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    claude-code.url = "github:sadjow/claude-code-nix";
    codex-cli.url = "github:sadjow/codex-cli-nix";

    devenv.url = "github:cachix/devenv";
    git-hooks.url = "github:cachix/git-hooks.nix";
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

      mkSystem = import ./lib/mkSystem.nix { inherit nixpkgs overlays inputs; };
    in
    {
      formatter = forEachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt);

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

      nixosConfigurations.nixos = mkSystem "nixos" {
        system = "aarch64-linux";
        user = "sandydoo";
        modules = [
          ./modules/sway.nix
          ./modules/tailscale.nix
        ];
      };

      nixosConfigurations.nixos-vmware = mkSystem "nixos-vmware" {
        system = "aarch64-linux";
        user = "sandydoo";
        modules = [
          ./modules/gnome.nix
          ./modules/tailscale.nix
        ];
      };

      nixosConfigurations.nixos-x86 = mkSystem "nixos-x86" {
        system = "x86_64-linux";
        user = "sandydoo";
        modules = [
          ./modules/i3.nix
          ./modules/tailscale.nix
        ];
      };

      darwinConfigurations.asdfpro = mkSystem "asdfpro" {
        system = "aarch64-darwin";
        user = "sandydoo";
        realUser = "sander";
        modules = [
          ./modules/darwin/blackhole.nix
        ];
      };
    };
}
