# VMware guest.
{ config, lib, ... }:

{
  config = lib.mkIf (config.machine.platform == "vmware") {
    virtualisation.vmware.guest.enable = true;
    virtualisation.vmware.guest.headless = false;

    boot.initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "nvme"
      "usbhid"
      "sr_mod"
    ];

    networking.nat.externalInterface = "enp0s1";

    # On aarch64, run x86_64-linux binaries and builds with QEMU user emulation.
    boot.binfmt.emulatedSystems = lib.mkIf config.nixpkgs.hostPlatform.isAarch64 [ "x86_64-linux" ];
  };
}
