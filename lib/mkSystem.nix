{
  nixpkgs,
  overlays,
  inputs,
}:

name:
{
  system,
  user,
  realUser ? null, # For macOS, use realUser if provided, otherwise use user
  modules ? [ ],
}:
let
  inherit (nixpkgs) lib;

  isDarwin = builtins.elem system [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  isLinux = !isDarwin;

  nixpkgsInput = if isDarwin then inputs.nixpkgs-darwin else nixpkgs;

  nixpkgsPatches = import ../patches/nixpkgs.nix {
    inherit (nixpkgs.legacyPackages.${system}) fetchpatch;
  };

  allPatches =
    nixpkgsPatches.common
    ++ (if isDarwin then nixpkgsPatches.darwin else nixpkgsPatches.linux);

  patchedNixpkgs =
    if allPatches == [ ] then
      nixpkgsInput
    else
      nixpkgs.legacyPackages.${system}.applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgsInput;
        patches = allPatches;
      };

  systemUser = if isDarwin && realUser != null then realUser else user;

  unstable = import inputs.nix-unstable {
    inherit system;
    config.allowUnfree = true;
    config.allowBroken = true;
    overlays = [
      inputs.neovim-nightly.overlays.default
      inputs.claude-code.overlays.default
      inputs.codex-cli.overlays.default
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
      {
        nixpkgs.source = patchedNixpkgs;
        nixpkgs.overlays = [
          (_: _: {
            inherit unstable;
            latest = unstable;
          })
          overlays.default
          overlays.darwin
        ];
      }
      inputs.home-manager.darwinModules.home-manager
    ];

  }
else
  nixpkgs.lib.nixosSystem {
    inherit specialArgs system;

    modules = baseModules ++ [
      { nixpkgs.source = patchedNixpkgs; }
      inputs.home-manager.nixosModules.home-manager
    ];
  }
