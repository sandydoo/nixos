{ pkgs, inputs, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    "${inputs.self}/machines/hardware/vmware-aarch64.nix"
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/remote-builder.nix"
    "${inputs.self}/modules/vmware-guest.nix"
    "${inputs.self}/modules/datadog-agent.nix"
  ];

  boot.kernelParams = [ "video=Virtual-1:3024x1964@60" ];
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  networking.hostName = "nixos-vmware";
  networking.nat.externalInterface = "enp0s1";

  nixpkgs.config.allowUnsupportedSystem = true;

  environment.systemPackages = with pkgs; [
    # VM
    virglrenderer
  ];

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/lib/nix-serve/cache-private-key.pem";
  };
}
