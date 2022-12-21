{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    nix-unstable.url = "github:NixOS/nixpkgs/6e51c97f1c849efdfd4f3b78a4870e6aa2da4198";
    home-manager.url = "github:nix-community/home-manager/release-22.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:msteen/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager, vscode-server }@inputs:
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
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.sandydoo = import ./users/sandydoo/home.nix;
          }
          {
            # Let 'nixos-version --json' know about the Git revision
            # of this flake.
            system.configurationRevision =
              nixpkgs.lib.mkIf (self ? rev) self.rev;
          }
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
