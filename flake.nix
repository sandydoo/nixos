{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/22.11-beta";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:msteen/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager, vscode-server, ... }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs [ "aarch64-linux" "x86_64-linux" ];
    in
    {
      formatter = forEachSystem (system: nix-unstable.legacyPackages.${system}.nixfmt);

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";

        modules = [
          vscode-server.nixosModule
          ./machines/nixos/configuration.nix
          ./users/sandydoo.nix
          ./gnome.nix
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

      nixosConfigurations.superstrizh = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules = [
          vscode-server.nixosModule
          ./machines/superstrizh/configuration.nix
          ./users/sandydoo.nix
          ./i3.nix
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
    };
}
