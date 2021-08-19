{ pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/virtualbox-image.nix"
    "${modulesPath}/virtualisation/virtualbox-guest.nix"
    "${modulesPath}/installer/cd-dvd/channel.nix"
  ];

  virtualisation.virtualbox.guest.enable = true;

  # Mount a VirtualBox shared folder.
  # This is configurable in the VirtualBox menu at
  # Machine / Settings / Shared Folders.
  # fileSystems."/mnt" = {
  #   fsType = "vboxsf";
  #   device = "nameofdevicetomount";
  #   options = [ "rw" ];
  # };
}
