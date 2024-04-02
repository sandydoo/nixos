{ pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;
    layout = "us";

    desktopManager = { xterm.enable = true; };

    displayManager.defaultSession = "none+i3";
    displayManager.lightdm.enable = true;
    displayManager.autoLogin = {
      enable = true;
      user = "sandydoo";
    };

    windowManager.i3.enable = true;
    windowManager.i3.package = pkgs.i3-gaps;
    windowManager.i3.extraPackages = with pkgs; [ dmenu i3status ];
  };
}

