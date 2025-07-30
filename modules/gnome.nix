{ config, pkgs, ... }:

{
  services.xserver.enable = true;

  services.displayManager = {
    gdm = {
      enable = true;
      wayland = true;
      autoSuspend = false;
    };
    defaultSession = "gnome";
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };

  services.desktopManager.gnome.enable = true;

  # Fix broken auto-login
  # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.systemPackages = [
    pkgs.gnome-tweaks
    pkgs.wl-clipboard
    pkgs.waypipe
  ];

  programs.dconf.enable = true;
  programs.xwayland.enable = true;
}
