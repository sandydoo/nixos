{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false;
    };
    desktopManager.gnome.enable = true;
  };

  services.displayManager = {
    defaultSession = "gnome";
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };

  # services.dbus.packages = [ pkgs.dconf ];
  # services.udev.packages = [ pkgs.gnome.gnome-settings-daemon ];

  programs.xwayland.enable = true;
}
