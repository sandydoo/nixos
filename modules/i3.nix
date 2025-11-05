{ pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  services.xserver = {
    enable = true;
    xkb.layout = "us";

    desktopManager = {
      xterm.enable = true;
    };

    displayManager.lightdm.enable = true;

    windowManager.i3.enable = true;
    windowManager.i3.extraPackages = with pkgs; [
      dmenu
      i3status
    ];
  };

  services.displayManager = {
    defaultSession = "none+i3";
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };
}
