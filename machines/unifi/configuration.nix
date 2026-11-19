{ inputs, lib, modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.unifi-os-server.nixosModules.unifi-os-server
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  machine.platform = "apple-vz";
  machine.app = "utm";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "unifi";
  networking.dhcpcd.wait = "ipv4";
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  services.unifi-os-server = {
    enable = true;
    openFirewallUiPort = true;
    openFirewallServicePorts = true;
  };

  # Replace the module's loopback inform address with the current DHCP address.
  systemd.services.podman-unifi-os-server = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    preStart = lib.mkOrder 1600 ''
      ip=$(${pkgs.iproute2}/bin/ip -j -4 route get 1.1.1.1 | ${pkgs.jq}/bin/jq -er '.[0].prefsrc')
      sed -i "s/^system_ip=.*/system_ip=$ip/" /var/lib/unifi-os-server/unifi/system.properties
    '';
  };

  programs.fish.enable = true;
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05";
}
