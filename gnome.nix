{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    displayManager.gdm.autoSuspend = false;
    displayManager.defaultSession = "gnome";
    displayManager.autoLogin = {
      enable = true;
      user = "sandydoo";
    };
    desktopManager.gnome.enable = true;
  };

  # services.dbus.packages = [ pkgs.dconf ];
  # services.udev.packages = [ pkgs.gnome.gnome-settings-daemon ];

  programs.xwayland.enable = false;
}
