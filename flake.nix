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
    let system = "aarch64-linux";
    in {
      formatter.${system} = nix-unstable.legacyPackages.${system}.nixfmt;

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          vscode-server.nixosModule
          ./machines/nixos/configuration.nix
          ./users/sandydoo.nix
          ./gnome.nix
          # ./i3.nix
          ./modules/tailscale.nix
          home-manager.nixosModules.home-manager
        ];

        specialArgs = inputs // {
          unstable = import nix-unstable {
            inherit system;
            config.allowUnfree = true;
            config.allowBroken = true;
          };
        };
      };
    };
}
