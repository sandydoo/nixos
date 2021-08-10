{ config, pkgs, stdenv, lib, ... }:

with lib;

let
  allowUnfree = { allowUnfree = true; };
  unstable = import <unstable> { config = allowUnfree; };
in
{
  # Nix store

  nix.extraOptions = ''
    keep-derivations = true
    keep-outputs = true
    min-free = ${toString (1024 * 1024 * 1024)}
  '';

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


  # Hardware and kernel

  boot.kernelPackages = pkgs.linuxPackages_5_12;

  hardware = {
    opengl.extraPackages = [ pkgs.intel-ocl ];
    pulseaudio.enable = true;
  };

  virtualisation.virtualbox.guest.enable = true;


  # Modules

  disabledModules = [ "services/networking/tailscale.nix" ];

  imports = [
    <nixpkgs/nixos/modules/virtualisation/virtualbox-image.nix>
    <nixpkgs/nixos/modules/virtualisation/virtualbox-guest.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
    <unstable/nixos/modules/services/networking/tailscale.nix>
  ];


  # Package overrides and overlays

  nixpkgs.config = allowUnfree // {
    packageOverrides = pkgs: {
      # Use latest tailscale
      tailscale = unstable.tailscale;
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      linuxPackages_5_12 = super.linuxPackages_5_12.extend (lpself: lpsuper: {
        # Use latest guest additions
        virtualboxGuestAdditions = unstable.linuxPackages_5_12.virtualboxGuestAdditions;
      });
    })
  ];


  # Users

  users.users.sandydoo = {
    isNormalUser = true;
    home = "/home/sandydoo";
    createHome = true;
    description = "Sander";
    extraGroups = [ "wheel" "networkmanager" "vboxsf" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me"
    ];
  };

  # Mount a VirtualBox shared folder.
  # This is configurable in the VirtualBox menu at
  # Machine / Settings / Shared Folders.
  # fileSystems."/mnt" = {
  #   fsType = "vboxsf";
  #   device = "nameofdevicetomount";
  #   options = [ "rw" ];
  # };

  programs = {
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  time.timeZone = "Europe/Moscow";

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
    allowedTCPPorts = [ 22 ];
  };

  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      passwordAuthentication = false;
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';
    };
    sshd.enable = true;
    tailscale.enable = true;
    dbus.packages = [ pkgs.gnome.dconf ];
    udev.packages = [ pkgs.gnome.gnome-settings-daemon ];
    xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager = {
        gdm.enable = true;
        autoLogin = {
          enable = true;
          user = "sandydoo";
        };
      };
    };
  };

  # List packages installed in system profile. To search, run:
  # \$ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    fish
    fd
    vim
    kakoune
    git
    unstable.gh
    gnupg
    pinentry-gnome
    python3
    openssl
    dnsutils
    nftables
    nodejs-14_x
    nodePackages.npm
    nodePackages.yarn
    unstable.tailscale
    glxinfo
    google-chrome
    firefox
    iperf3
    openvpn
    wireguard-tools
    ocl-icd
    clinfo
  ];
}
