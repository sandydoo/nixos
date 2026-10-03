# Guest of Apple's Virtualization framework.
#
# App-specific settings, such as the Rosetta virtiofs tag, are in apps/.
{
  config,
  inputs,
  lib,
  ...
}:

let
  inherit (config.machine) host;
in
{
  imports = [ inputs.disko.nixosModules.disko ];

  config = lib.mkIf (config.machine.platform == "apple-vz") (
    lib.mkMerge [
      (import ./disko.nix)
      {
        boot.initrd.availableKernelModules = [
          "virtio_pci"
          "xhci_pci"
          "usb_storage"
          "usbhid"
        ];

        # The app chooses the PCI slot. enp0s1 is correct for UTM.
        networking.nat.externalInterface = "enp0s1";

        # Rosetta for Linux needs an Apple silicon host.
        # Run x86_64-linux binaries and builds with it.
        # The app must share Rosetta, or /run/rosetta does not mount.
        virtualisation.rosetta.enable = host.isDarwin && host.isAarch64;
      }
    ]
  );
}
