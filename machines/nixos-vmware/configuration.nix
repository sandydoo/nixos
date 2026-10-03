{ inputs, ... }:

{
  imports = [
    ./hardware.nix
    "${inputs.self}/modules/dev-vm.nix"
    "${inputs.self}/modules/datadog-agent.nix"
  ];

  machine.platform = "vmware";
  machine.app = "vmware-fusion";

  networking.hostName = "nixos-vmware";

  # Native resolution of the host's display (MacBook Pro, asdfpro).
  boot.kernelParams = [ "video=Virtual-1:3024x1964@60" ];

  nixpkgs.config.allowUnsupportedSystem = true;
}
