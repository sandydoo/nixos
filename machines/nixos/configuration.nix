{ pkgs, inputs, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    "${inputs.self}/modules/common.nix"
  ];

  boot.kernelParams = [ "video=Virtual-1:3024x1964@60" ];
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  networking.hostName = "nixos";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s1 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        # Configured by the macOS host. See README.md for details.
        address = "192.168.64.2";
        prefixLength = 24;
      }
    ];
    ipv4.routes = [
      {
        address = "0.0.0.0";
        prefixLength = 0;
        via = "192.168.64.1";
      }
    ];
    ipv6.addresses = [
      {
        address = "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6";
        prefixLength = 64;
      }
    ];
    ipv6.routes = [
      {
        address = "::";
        prefixLength = 0;
        via = "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6";
      }
    ];
  };
  networking.nameservers = [ "192.168.64.1" "fdc6:a11c:ce40:6c86:10cb:1e63:905d:2dd6" ];

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "enp0s1";

  networking.firewall.enable = false;

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "br0" "virbr0" ];

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  # services.spice-webdavd.enable = true;

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/lib/nix-serve/cache-private-key.pem";
  };

  environment.systemPackages = with pkgs; [
    # VM
    # Graphics driver for QEMU guests
    virglrenderer

    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
  ];
}
