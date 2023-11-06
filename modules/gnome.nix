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
    desktopManager.gnome.extraGSettingsOverrides = ''
      [org.gnome.desktop.interface]
      scaling-factor = 2
    '';
  };

  # services.gnome.gnome-settings-daemon.enable = true;

  programs.xwayland.enable = false;
}
