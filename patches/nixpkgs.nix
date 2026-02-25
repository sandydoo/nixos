{ fetchpatch }:
{
  common = [ ];

  darwin = [
    # yt-dlp: exclude secretstorage dependency on Darwin
    # https://github.com/NixOS/nixpkgs/pull/493943
    (fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/pull/493943.patch";
      hash = "sha256-skGGebqoQ9ouT7qJsIg5EQz3v+9VRxoYJ1o/8zRPHto=";
    })
  ];

  linux = [ ];
}
