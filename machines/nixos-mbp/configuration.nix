{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    "${inputs.self}/machines/hardware/macbook-pro-9-2.nix"
    "${inputs.self}/modules/common.nix"

    # nixos-hardware does not ship a 9-2 profile.
    # Pull in the generic Apple MacBook Pro defaults
    # (Intel CPU microcode, laptop power management).
    inputs.nixos-hardware.nixosModules.apple-macbook-pro
    inputs.nixos-hardware.nixosModules.common-pc-laptop-ssd
  ];

  networking.hostName = "nixos-mbp";

  # Broadcom BCM4331 Wi-Fi (MacBook Pro 9,2).
  # The mainline `b43` driver supports BCM4331 with the redistributable
  # firmware enabled by `enableB43Firmware`.
  # If `b43` proves unstable, switch to the proprietary `wl` driver:
  #   boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  #   boot.kernelModules = [ "wl" ];
  #   boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" ];
  networking.enableB43Firmware = true;
  hardware.enableRedistributableFirmware = true;

  # facetimehd out-of-tree module fails to build on kernel 7.x
  # (struct vb2_ops .wait_prepare/.wait_finish removed upstream).
  # Apple iSight webcam unsupported until upstream patch lands.
  hardware.facetimehd.enable = lib.mkForce false;

  # NetworkManager handles Wi-Fi roaming better on a laptop than networkd.
  networking.networkmanager.enable = true;
  networking.useNetworkd = lib.mkForce false;
  systemd.network.enable = lib.mkForce false;

  time.timeZone = "Europe/Madrid";

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  system.stateVersion = lib.mkForce "25.11";
}
