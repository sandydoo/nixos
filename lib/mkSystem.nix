{
  nixpkgs,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  modules ? [ ],
}:
let
  isDarwin = builtins.elem system [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  isLinux = !isDarwin;

  unstable = import inputs.nix-unstable {
    inherit system;
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.neovim-nightly.overlays.default
    ];
  };

  specialArgs = inputs // {
    inherit inputs isLinux unstable;
  };

  baseModules = [
    ../machines/${name}/configuration.nix
  ]
  ++ (if isLinux then [ ../users/${user}.nix ] else [ ])
  ++ modules;

in
if isDarwin then
  inputs.darwin.lib.darwinSystem {
    inherit specialArgs system;

    modules = baseModules ++ [
      (
        { ... }:
        {
          nixpkgs.overlays = [
            (_: _: {
              inherit unstable;
              latest = unstable;
            })
            overlays.default
            overlays.darwin
          ];
        }
      )
      inputs.home-manager.darwinModules.home-manager
    ];

  }
else
  nixpkgs.lib.nixosSystem {
    inherit specialArgs system;

    modules = baseModules ++ [
      inputs.home-manager.nixosModules.home-manager
      inputs.vscode-server.nixosModule
    ];
  }
