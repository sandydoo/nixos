# Development VM: the role that nixos-x86, nixos-vmware and nixos-utm share.
#
# The parts that depend on the hypervisor are in platforms/<platform>.
{
  imports = [
    ./common.nix
    ./remote-builder.nix
  ];

  # NAT for nspawn containers. The platform sets the external interface.
  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];

  networking.firewall.enable = false;

  virtualisation.libvirtd.allowedBridges = [
    "br0"
    "virbr0"
  ];
}
