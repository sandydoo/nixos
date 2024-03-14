{ config, pkgs, lib, unstable, ... }:

{
  services.tailscale = {
    enable = true;
    package = unstable.tailscale;
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    checkReversePath =
      "loose"; # Required for exit nodes and certain subnet routing setups
  };
}
