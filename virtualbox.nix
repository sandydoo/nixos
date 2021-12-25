{ nix-unstable, ... }:

{
  imports = [
    "${nix-unstable}/nixos/modules/virtualisation/virtualbox-image.nix"
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
