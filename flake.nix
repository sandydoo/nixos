{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    nix-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-22.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server.url = "github:msteen/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-unstable, home-manager, vscode-server }@inputs:
    let system = "x86_64-linux";
    in {
      formatter.${system} = nix-unstable.legacyPackages.${system}.nixfmt;

      nixosConfigurations.superstrizh = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          vscode-server.nixosModule
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
            system.configurationRevision =
              nixpkgs.lib.mkIf (self ? rev) self.rev;
          }
        ];

        specialArgs = inputs // {
          unstable = import nix-unstable {
            inherit system;
            config.allowUnfree = true;
          };
        };
      };
    };
}
