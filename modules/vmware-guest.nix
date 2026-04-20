{ ... }:

{
  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = false;

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];

  networking.firewall.enable = false;

  virtualisation.libvirtd.allowedBridges = [
    "br0"
    "virbr0"
  ];
}
