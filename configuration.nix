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
  password = "horses have feelings";
  extraGroups = [ "wheel" "networkmanager" "vboxsf" ];

  openssh = {
    authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDG4Q5+NEeBld93cAoJDjSLYna5+em6FdRjRrXCEqJ87yA9rNqZvs28SpJkZ2xfYY13FljSgI9u3WLRDYUwbRj8AeRLz51dmV5t3katVe7Ho6NH0rxpMxyPilFuwidZBBNGpDirmJQuej9k2zOgl+VOw8PkfqCPoystY6RGna+N1izywFcHPVtN2fdAHQLgdTZ5dQAwDi4whXeVtxRD0mFZUKI4OwjEUNPScueFmOdBbQG4z7nIbjYdq6QxjCcrWzfAKugpOKIcfQNFkKD6NKiYvobRYFo8IarD11HiPMz4eZ9kZIsI9104awOTAsxoXmBccww0s7rWsm3Nsr2i8Xgn8V2MxV3e/D1LxyFu2s0QJbJtPx4+POYOO78QzI3DihcmoMB9XwPx9m8U0349mgT3KtVSLqxI8a8ePhs4lDCtV4Jp34/mjg+piOPdrfiKLRlORxL+eq8SkOYkgtxvqn/+mB5HBRidxOKYpW/ya84nKyRPr+wufVJR6FBdUaVDGDs/nzALrQr7eWc3c9Yzib1HFanxErdzXp0eMRQu9FavFQuL3M4DlvovR5O9hEs64XUGQeNQTyRmb/wJTxP98dV04sEuUfPe2SzSJF0QwdqIVZNp0jLDww1GRZyrAG1FQ1bNpeeQ/lpd0tCYHY3H6w7+ZSMSCM632irUEqSb3QNvKQ== General key for Sander on asdf"
    ];
  };
};

programs.ssh = {
  startAgent = true;
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
