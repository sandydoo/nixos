{ pkgs, ... }:

{
  services.displayManager = {
    defaultSession = "sway";
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
  };

  programs.sway.enable = true;
  programs.xwayland.enable = true;

  environment.systemPackages = [ pkgs.wdisplays ];
}
