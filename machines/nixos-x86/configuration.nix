{ pkgs, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    "${inputs.self}/machines/hardware/vmware-x86_64.nix"
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/remote-builder.nix"
    "${inputs.self}/modules/vmware-guest.nix"
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

  networking.nat.externalInterface = "ens33";

  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;

  nix.settings.system-features = [
    "big-parallel"
    "kvm"
    "nixos-test"
  ];
  nix.settings.max-jobs = 3;
  nix.settings.cores = 2;

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = false;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  environment.systemPackages = with pkgs; [
    # VM
    xf86-video-vmware
    virt-manager
  ];
}
