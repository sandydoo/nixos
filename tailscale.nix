{ pkgs, ... }:

{
  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    <unstable/nixos/modules/services/networking/tailscale.nix>
  ];

  nixpkgs.config = {
    packageOverrides = pkgs: {
      # Use latest tailscale
      tailscale = unstable.tailscale;
    };
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  environment.systemPackages = with pkgs; [
    tailscale
  ];
}
