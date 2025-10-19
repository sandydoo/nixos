{
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/remote-builder.nix"
  ];

  networking.hostName = "nixos-x86";
  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  networking.hosts = {
    "127.0.0.2" = [
      "nixos-x86"
      "test.nixos-x86"
      "api.nixos-x86"
      "app.nixos-x86"
    ];
  };

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "ens33";

  # Bridge for VMs
  networking.bridges = {
    # br0.interfaces = ["ens33"] ;
    # virbr0.interfaces = [];
  };
  # networking.interfaces.virbr0.useDHCP = true;

  # Disable the firewall for now.
  networking.firewall.enable = false;

  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = false;

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [
    "br0"
    "virbr0"
  ];
  programs.dconf.enable = true;

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  nix.settings.system-features = [
    "big-parallel"
    "kvm"
    "nixos-test"
  ];

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = false;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Graphics
    # renderdoc

    # VM
    xorg.xf86videovmware
    virt-manager
  ];
}
