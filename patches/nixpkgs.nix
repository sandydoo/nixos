{ fetchpatch }:
{
  common = [
    (fetchpatch {
      # direnv: no external linkmode
      url = "https://github.com/NixOS/nixpkgs/commit/a4fb16db2751d9c9e5f3512c697d2ac49d406789.patch";
      hash = "sha256-lGexSgro3iG3KwHOrjNricJPd5brJyoO6B6xg794VXo=";
    })
  ];

  darwin = [ ];

  linux = [ ];
}
