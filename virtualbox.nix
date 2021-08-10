{
  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  # Use latest guest additions
  nixpkgs.overlays = [
    (self: super: {
      linuxPackages_5_12 = super.linuxPackages_5_12.extend (lpself: lpsuper: {
        virtualboxGuestAdditions = unstable.linuxPackages_5_12.virtualboxGuestAdditions;
      });
    })
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
