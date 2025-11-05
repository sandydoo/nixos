{ pkgs, inputs, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/remote-builder.nix"
  ];

  boot.kernelParams = [ "video=Virtual-1:3024x1964@60" ];
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  networking.hostName = "nixos-vmware";

  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = false;

  nixpkgs.config.allowUnsupportedSystem = true;

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "enp0s1";

  networking.firewall.enable = false;

  virtualisation.libvirtd.enable = false;
  virtualisation.libvirtd.allowedBridges = [
    "br0"
    "virbr0"
  ];

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    # VM
    virglrenderer
  ];

  services.datadog-agent = {
    enable = false;
    enableTraceAgent = true;
    site = "datadoghq.eu";
    apiKeyFile = "/run/datadog-agent";
    package = pkgs.datadog-agent.override { extraTags = [ "otlp" ]; };
    extraConfig = {
      logs_enabled = true;
      otlp_config = {
        receiver = {
          protocols = {
            http.endpoint = "localhost:4318";
            grpc.endpoint = "localhost:4317";
          };
        };
      };
    };
  };

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/lib/nix-serve/cache-private-key.pem";
  };
}
