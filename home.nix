{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gnome3.gnome-tweak-tool
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

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
      key = "171257C9C397032E";
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
}

