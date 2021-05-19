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
    extraConfig = {
      push = {
        default = "simple";
      };
    };
  };
}

