{ config, pkgs, inputs, unstable, nixpkgs, nix-unstable, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    "${inputs.self}/modules/common.nix"
    "${inputs.self}/modules/cachix.nix"
  ];

  hardware.opengl.extraPackages = [ pkgs.intel-ocl ];

  networking.hostName = "superstrizh";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  networking.hosts = {
    "127.0.0.2" = [ "superstrizh" "test.superstrizh" "api.superstrizh" "app.superstrizh" ];
  };

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "ens33";

  # Bridge for VMs
  networking.bridges = {
    # br0.interfaces = ["ens33"] ;
    # virbr0.interfaces = [];
  };
  # networking.interfaces.virbr0.useDHCP = true;

  # Disable the firewall for now.
  networking.firewall.enable = false;

  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = false;

  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "br0" "virbr0" ];
  programs.dconf.enable = true;

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  nix.settings.system-features = [ "big-parallel" "kvm" "nixos-test" ];

  # services.xserver = {
  #   enable = true;
  #   layout = "us";
  #   desktopManager.gnome.enable = true;
  #   displayManager = {
  #     gdm.enable = true;
  #     autoLogin = {
  #       enable = true;
  #       user = "sandydoo";
  #     };
  #   };
  #   # desktopManager.xterm.enable = false;

  #   # displayManager.defaultSession = "none+i3";
  #   # displayManager.autoLogin = {
  #   #   enable = false;
  #   #   user = "sandydoo";
  #   # };
  #   # displayManager.lightdm.enable = true;
  #   # # displayManager.lightdm.greeters.pantheon.enable = true;

  #   # windowManager.i3.enable = true;
  #   # windowManager.i3.package = pkgs.i3-gaps;
  #   # windowManager.i3.extraPackages = with pkgs; [ dmenu i3status ];
  # };

  # Serve the store as a binary cache
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # Graphics
    renderdoc

    # VM
    xorg.xf86videovmware
    virt-manager
  ];
}
