{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager }@inputs: {
    formatter.x86_64-linux = nix-unstable.legacyPackages.x86_64-linux.nixfmt;

    nixosConfigurations.superstrizh = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./machines/superstrizh/configuration.nix
        ./users/sandydoo.nix
        # ./gnome.nix
        ./i3.nix
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
          system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
        }
      ];

      specialArgs = inputs // {
        unstable = import nix-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };
    };
  };
}
