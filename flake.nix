{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-21.05";
    home-manager.inputs.nixpkgs.follows = "nix-unstable";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager }: {
    nix.registry.nixpkgs.flake = nixpkgs;
    nix.registry.unstable.flake = nix-unstable;

    nixosConfigurations.sandydoo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sandydoo = import ./home.nix;
        }
        {
          # Let 'nixos-version --json' know about the Git revision
          # of this flake.
          system.configurationRevision =
            nixpkgs.lib.mkIf (self ? rev) self.rev;
        }
      ];

      specialArgs = {
        inherit nix-unstable;
        unstable = import nix-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
    };
  };
}
