{ pkgs, inputs, ... }:

{
  imports = [
    "${inputs.self}/machines/hardware/utm-aarch64.nix"
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/remote-builder.nix"
    "${inputs.self}/modules/datadog-agent.nix"
  ];

  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  networking.hostName = "nixos-utm";
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp0s1";
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.firewall.enable = false;

  virtualisation.libvirtd.allowedBridges = [
    "br0"
    "virbr0"
  ];

  nixpkgs.config.allowUnsupportedSystem = true;

  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/lib/nix-serve/cache-private-key.pem";
  };
}
