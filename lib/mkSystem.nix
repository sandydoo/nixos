{
  nixpkgs,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  realUser ? null,
  modules ? [ ],
}:
let
  inherit (nixpkgs) lib;

  isDarwin = builtins.elem system [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  isLinux = !isDarwin;

  # For Darwin, use realUser if provided, otherwise use user
  systemUser = if isDarwin && realUser != null then realUser else user;

  unstable = import inputs.nix-unstable {
    inherit system;
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.neovim-nightly.overlays.default
    ];
  };

  specialArgs = inputs // {
    inherit
      inputs
      unstable
      isDarwin
      isLinux
      user
      systemUser
      ;
  };

  homeManagerModule =
    { config, ... }:
    {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.users.${systemUser} = import ../users/${user}/home.nix;
    };

  baseModules = [
    ../machines/${name}/configuration.nix
    homeManagerModule
  ]
  ++ lib.optionals isLinux [ ../users/${user}.nix ]
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
    ];
  }
