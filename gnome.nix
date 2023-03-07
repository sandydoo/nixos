{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    displayManager.defaultSession = "gnome";
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    displayManager.gdm.autoSuspend = false;
    displayManager.autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };

  # services.dbus.packages = [ pkgs.dconf ];
  # services.udev.packages = [ pkgs.gnome.gnome-settings-daemon ];

  programs.xwayland.enable = false;
}
