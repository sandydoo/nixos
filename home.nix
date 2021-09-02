{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gnome3.gnome-tweak-tool
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  home.sessionVariables = {
    EDITOR = "kak";
  };

  programs.fish = {
    enable = true;
    plugins = [
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "pure-fish";
          repo = "pure";
          rev = "v3.5.0";
          sha256 = "0nr97z138v93lmvi4zh4h09gi5mzaxk4j6rk4x3calk0vjgfw7qs";
        };
      }
    ];
  };

  programs.git = {
    enable = true;
    userName = "sandydoo";
    userEmail = "hey@sandydoo.me";
    signing = {
      key = "D1A763BC84F34603";
      signByDefault = true;
    };
    extraConfig = {
      core = {
        editor = "kak";
        quotepath = "off";
      };
      init.defaultbranch = "main";
      pull.ff = "simple";
      push.default = "simple";
    };
  };

  programs.gpg.enable = true;

  programs.gpg.settings = {
    # Use ASCII armored output instead of binary
    armor = true;

    # Show key IDs in 16-character format
    keyid-format = "0xlong";

    keyserver = "hkps://keys.openpgp.org";
    use-agent = true;
 };
}
