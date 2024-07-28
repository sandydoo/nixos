{ pkgs, inputs, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/cachix.nix"
    "${inputs.self}/modules/vmware-guest.nix"
  ];

  disabledModules = [ "virtualisation/vmware-guest.nix" ];

  boot.kernelParams = [ "video=Virtual-1:3024x1964@60" ];
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  networking.hostName = "nixos-vmware";

  virtualisation.vmware.guest.enable = true;

  nixpkgs.config.allowUnsupportedSystem = true;

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens160 = {
    useDHCP = true;
    # ipv4.addresses = [
    #   {
    #     # Configured by the macOS host. See README.md for details.
    #     address = "192.168.65.2";
    #     prefixLength = 24;
    #   }
    # ];
    # ipv4.routes = [
    #   {
    #     address = "0.0.0.0";
    #     prefixLength = 0;
    #     via = "192.168.65.1";
    #   }
    # ];
    # ipv6.addresses = [
    #   {
    #     address = "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6";
    #     prefixLength = 64;
    #   }
    # ];
    # ipv6.routes = [
    #   {
    #     address = "::";
    #     prefixLength = 0;
    #     via = "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6";
    #   }
    # ];
  };
  # networking.nameservers = [ "192.168.64.1" "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6" ];

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "enp0s1";

  networking.firewall.enable = false;

  virtualisation.libvirtd.enable = false;
  virtualisation.libvirtd.allowedBridges = [ "br0" "virbr0" ];

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    # VM
    virglrenderer

    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ];
}
