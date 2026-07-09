{
  inputs,
  overlays,
}:

name:
{
  system,
  user,
  nixUser ? user, # Use another /users config
  modules ? [ ],
  homeModules ? [ ],
}:
let
  inherit (inputs.nixpkgs) lib;

  isDarwin = builtins.elem system [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  isLinux = !isDarwin;

  nixpkgsInput = if isDarwin then inputs.nixpkgs-darwin else inputs.nixpkgs;

  nixpkgsPatches = import ../patches/nixpkgs.nix {
    inherit (inputs.nixpkgs.legacyPackages.${system}) fetchpatch;
  };

  allPatches =
    nixpkgsPatches.common ++ (if isDarwin then nixpkgsPatches.darwin else nixpkgsPatches.linux);

  patchedNixpkgs =
    if allPatches == [ ] then
      nixpkgsInput
    else
      inputs.nixpkgs.legacyPackages.${system}.applyPatches {
        name = "nixpkgs-patched";
        src = nixpkgsInput;
        patches = allPatches;
      };

  unstable = import inputs.nixpkgs-unstable {
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
      nixUser
      ;
  };

  homeManagerModule =
    { config, ... }:
    {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;
      home-manager.extraSpecialArgs = specialArgs;
      home-manager.users.${user} = {
        imports = [ (import ../users/${nixUser}/home.nix) ] ++ homeModules;
      };
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
  inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs system;

    modules =
      baseModules
      ++ lib.optional (allPatches != [ ]) {
        inputs.nixpkgs.flake.source = lib.mkForce patchedNixpkgs;
      }
      ++ [
        inputs.home-manager.nixosModules.home-manager
      ];
  }
