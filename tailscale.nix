{ config, pkgs, ... }:

{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    <unstable/nixos/modules/services/networking/tailscale.nix>
  ];

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  environment.systemPackages = with pkgs; [
    unstable.tailscale
  ];
}
