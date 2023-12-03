{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin";
    darwin.url = "github:LnL7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:msteen/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager, darwin, nix-darwin, vscode-server, ... }@inputs:
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
          unstable = import nix-unstable {
            system = "aarch64-linux";
            config.allowUnfree = true;
            config.allowBroken = true;
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
          unstable = import nix-unstable {
            system = "x86_64-linux";
            config.allowUnfree = true;
            config.allowBroken = true;
          };
        };
      };

      darwinConfigurations.asdfPro =
        darwin.lib.darwinSystem (let
          latest = _: _: {
            latest = import nix-unstable {
              system = "aarch64-darwin";
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.allowBroken = true;
            };
          };
        in {
          system = "aarch64-darwin";

          modules = [
            ({ ... }: {
              nixpkgs.overlays = [
                latest
                (import ./overlays)
                (import ./overlays/darwin.nix)
              ];
            })
            ./machines/asdfpro/configuration.nix
          ];
          specialArgs = { inherit nix-unstable; nixpkgs = nix-darwin; };
        });
    };
}
