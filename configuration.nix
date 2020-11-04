{ config, pkgs, stdenv, lib, ... }:

with lib;

{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

# Mount a VirtualBox shared folder.
# This is configurable in the VirtualBox menu at
# Machine / Settings / Shared Folders.
# fileSystems."/mnt" = {
#   fsType = "vboxsf";
#   device = "nameofdevicetomount";
#   options = [ "rw" ];
# };

users.users.sandydoo = {
  isNormalUser = true;
  home = "/home/sandydoo";
  createHome = true;
  description = "Sander";
  password = "36rt!SAN";
  extraGroups = [ "wheel" "networkmanager" "vboxsf" ];

  openssh = {
    authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC09+9lHBD1vhwnRlt/3gjxiwpfGAc7p5FEJdoxX/7fc8eWFVlUVveTfhAbK/nU8RXuaqPTxhg+cmUw/oeD3l+NzB1cwqtqAmneQ6Bdg06BuMa2/GYB+ScbcHuybQA/zQuqnKe8RlWpl4JhltSFrM/u7WgFh1O66EZIUC2r2NiUYhVuA5ocZlD3U9j+BZiQFq/ZXNF12Lz+6nZFfewOkBdV6KX7Nk9UJ2Y0L4YnEUWZ638uu6PqMEhGejmRVVF1zQfAYxBjP/f0a33L6kAzAHxISOSdSbhR8WbC2I2lD+WR6NCumIy4drASRnzVV6xZYOJA0yYyDbzg0qc/udoCzPVp Sander@Sanders-MacBook-Pro.local"
    ];
  };
};

services.xserver = {
  enable = true;
  displayManager = {
    gdm.enable = true;
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };
  desktopManager.gnome3.enable = true;
  videoDrivers = mkOverride 40 [ "virualbox" "vmware" ];
};

# Set your time zone.
time.timeZone = "Europe/Moscow";

services = {
  openssh = {
    enable = true;
    passwordAuthentication = false;
  };
  tailscale.enable = true;
  dbus.packages = [ pkgs.gnome3.dconf ];
  udev.packages = [ pkgs.gnome3.gnome-settings-daemon ];
};

hardware.pulseaudio.enable = true;

# List packages installed in system profile. To search, run:
# \$ nix search wget
environment.systemPackages = with pkgs; [
  home-manager
  vim
  git
  tailscale
  glxinfo
  firefox
  linuxPackages.virtualboxGuestAdditions
];

}
