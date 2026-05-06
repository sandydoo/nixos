{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    "${inputs.self}/machines/hardware/macbook-pro-11-1.nix"
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/applesmc-bclm.nix"

    inputs.nixos-hardware.nixosModules.apple-macbook-pro-11-1
  ];

  networking.hostName = "nixos-mbp";

  # Broadcom BCM4360 Wi-Fi (PHY type AC, 802.11ac).
  # `b43` does not support this PHY ("FOUND UNSUPPORTED PHY ... Type 11 (AC)").
  # Use the proprietary `wl` driver from broadcom_sta.
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelModules = [ "wl" ];
  boot.blacklistedKernelModules = [ "b43" "bcma" "ssb" "brcmsmac" "brcmfmac" ];

  # broadcom-sta is unmaintained and has known WiFi-packet RCEs
  # (CVE-2019-9501, CVE-2019-9502). No alternative driver supports
  # the BCM4360 in this MacBook on Linux.
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "broadcom-sta" ];

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

  services.applesmc-bclm = {
    enable = true;
    limit = 80;
  };

  system.stateVersion = lib.mkForce "25.11";

  # Disable GPG on this host: gpg 2.4+ keyboxd default breaks HM
  # publicKeys import during activation, and this machine has no
  # signing/encryption use case yet.
  home-manager.users.sandydoo = { lib, ... }: {
    programs.gpg.enable = lib.mkForce false;
    programs.gpg.publicKeys = lib.mkForce [ ];
  };
}
