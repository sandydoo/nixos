{ pkgs, ... }:

{
  services.xserver = {
    enable = true;

    displayManager = {
      defaultSession = "sway";
      lightdm.enable = true;
      autoLogin = {
        enable = true;
        user = "sandydoo";
      };
    };
  };

  programs.sway.enable = true;
  programs.xwayland.enable = true;

  environment.systemPackages = [ pkgs.wdisplays ];
}
