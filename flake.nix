{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    darwin.url = "github:LnL7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs = {
        nixpkgs.follows = "nix-unstable";
        flake-compat.follows = "";
        git-hooks.follows = "";
        hercules-ci-effects.follows = "";
      };
    };
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager, darwin, vscode-server, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
    in
    {
      formatter = forEachSystem (system: nix-unstable.legacyPackages.${system}.nixfmt);

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          ./machines/nixos/configuration.nix
          ./users/sandydoo.nix
          ./modules/sway.nix
          ./modules/tailscale.nix
          home-manager.nixosModules.home-manager
        ];

        specialArgs = inputs // {
          inherit inputs;
          isLinux = true;
          unstable = import nix-unstable {
            system = "aarch64-linux";
            config.allowUnfree = true;
            config.allowBroken = true;
            overlays = [
              inputs.neovim-nightly.overlays.default
            ];
          };
        };
      };

      nixosConfigurations.nixos-vmware = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          ./machines/nixos-vmware/configuration.nix
          ./users/sandydoo.nix
          ./modules/gnome.nix
          ./modules/tailscale.nix
          home-manager.nixosModules.home-manager
        ];

        specialArgs = inputs // {
          inherit inputs;
          isLinux = true;
          unstable = import nix-unstable {
            system = "aarch64-linux";
            config.allowUnfree = true;
            config.allowBroken = true;
            overlays = [
              inputs.neovim-nightly.overlays.default
            ];
          };
        };
      };

      nixosConfigurations.nixos-x86 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          vscode-server.nixosModule
          ./machines/superstrizh/configuration.nix
          ./users/sandydoo.nix
          ./modules/i3.nix
          ./modules/tailscale.nix
          home-manager.nixosModules.home-manager
        ];

        specialArgs = inputs // {
          inherit inputs;
          isLinux = true;
          unstable = import nix-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
            config.allowBroken = true;
          };
        };
      };

      darwinConfigurations.asdfPro =
        darwin.lib.darwinSystem (let
          system = "aarch64-darwin";
          latest = _: _: {
            latest = import nix-unstable {
              inherit system;
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.allowBroken = true;
            };
          };
        in {
          inherit system;

          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                latest
                (import ./overlays)
                (import ./overlays/darwin.nix)
              ];
            })
            ./machines/asdfpro/configuration.nix
            home-manager.darwinModules.home-manager
          ];
          specialArgs = { 
            inherit inputs nix-unstable nixpkgs;
            isLinux = false;
            unstable = import nix-unstable {
              inherit system;
              config.allowUnfree = true;
              config.allowBroken = true;
              overlays = [
                inputs.neovim-nightly.overlays.default
              ];
            };
          };
        });
    };
}
