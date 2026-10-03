# Hyper-V guest.
{ config, lib, ... }:

{
  config = lib.mkIf (config.machine.platform == "hyperv") {
    virtualisation.hypervGuest.enable = true;

    boot.initrd.availableKernelModules = [ "sd_mod" ];

    # Hyper-V netvsc interfaces don't get predictable names; they show up as eth0.
    networking.interfaces.eth0.useDHCP = lib.mkDefault true;
    networking.nat.externalInterface = "eth0";
  };
}
