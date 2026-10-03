# Installer ISO for the UTM VM.
#
# The Apple Virtualization backend cannot send keystrokes to the guest.
# So the stock ISO cannot be unlocked without a person at the console.
# This ISO lets root log in with SSH at once, for nixos-anywhere.
{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # Same key as users/sandydoo.nix.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me"
  ];

  # The ISO is rebuilt often and used once. Compress fast.
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";
}
