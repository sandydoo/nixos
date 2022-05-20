{ config, nix-unstable, unstable, ... }:

{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports =
    [ "${nix-unstable}/nixos/modules/services/networking/tailscale.nix" ];

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
