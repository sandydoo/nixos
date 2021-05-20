{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    gnome3.gnome-tweak-tool
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

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

