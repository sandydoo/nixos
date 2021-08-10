{ config, pkgs, stdenv, lib, ... }:

with lib;

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


  # Package overrides and overlays

  nixpkgs.config = {
    # Allow proprietary packages
    allowUnfree = true;

    overlays = [
      (self: super: {
        unstable = (import <unstable> { config = super.config; });
      })
    ];

    # Add an alias for the unstable channel
    packageOverrides = pkgs: {
      unstable = import <unstable> { config = config.nixpkgs.config; };
    };
  };

  # Modules

  imports = [
    ./virtualbox.nix
    ./tailscale.nix
  ];


  # Users

  users.users.sandydoo = {
    home = "/home/sandydoo";
    description = "Sander";
    extraGroups = [ "wheel" "networkmanager" "vboxsf" ];
    isNormalUser = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me"
    ];
    shell = pkgs.fish;
  };

  programs = {
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };
  };

  time.timeZone = "Europe/Moscow";

  networking.hostName = "sandydoo";

  networking.firewall = {
    enable = true;
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
