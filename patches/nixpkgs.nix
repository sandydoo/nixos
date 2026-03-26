{ fetchpatch }:
{
  common = [
    (fetchpatch {
      # direnv: no external linkmode
      url = "https://github.com/NixOS/nixpkgs/commit/d6f179cad8ac8f752264a7ed4fa7e3c9a1f5c2c1.patch";
      hash = "sha256-5gSEUjFiQcV7XpsiqfYg2v78JiK7i9ttM3x8JJ/K1pY=";
    })
  ];

  darwin = [ ];

  linux = [ ];
}
