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

  # Fix broken auto-login
  # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.systemPackages = [
    pkgs.gnome.gnome-tweaks
  ];

  programs.dconf.enable = true;
  programs.xwayland.enable = true;
}
