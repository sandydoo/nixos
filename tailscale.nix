{ config, pkgs, ... }:

{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    <unstable/nixos/modules/services/networking/tailscale.nix>
  ];

  #nixpkgs.config = {
  #  packageOverrides = with pkgs; {
  #    # Use latest tailscale
  #    tailscale = unstable.tailscale;
  #  };
  #};

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  environment.systemPackages = with pkgs; [
    unstable.tailscale
  ];
}
