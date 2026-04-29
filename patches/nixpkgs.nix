{ fetchpatch }:
{
  common = [ ];

  darwin = [
    (fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/a25cd2de2d32b1ac1bb752b3ccccfe55a7a5019d.patch";
      hash = "sha256-KMKnApUzF90EC4VqKelOIEvRbfLDxW7ZpSd/oFflb4M=";
    })
  ];

  linux = [ ];
}
