{ config, pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;

    desktopManager = { xterm.enable = false; };

    displayManager.defaultSession = "none+i3";
    displayManager.autoLogin = {
      enable = true;
      user = "sandydoo";
    };
    displayManager.lightdm.enable = true;
    displayManager.lightdm.greeters.pantheon.enable = true;

    windowManager.i3.enable = true;
    windowManager.i3.package = pkgs.i3-gaps;
    windowManager.i3.extraPackages = with pkgs; [ dmenu i3status ];
  };
}

