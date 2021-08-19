{ config, pkgs, nix-unstable, unstable, ... }:

{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    "${nix-unstable}/nixos/modules/services/networking/tailscale.nix"
  ];

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  environment.systemPackages = [
    unstable.tailscale
  ];
}
