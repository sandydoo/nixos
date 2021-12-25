{ config, pkgs, nix-unstable, unstable, stdenv, lib, ... }:

with lib;

{
  # Nix store

  nix.package = pkgs.nixUnstable;

  nix.extraOptions = ''
    keep-derivations = true
    keep-outputs = true
    min-free = ${toString (1024 * 1024 * 1024)}
    experimental-features = nix-command flakes
  '';

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };


  # Nix packages

  # Allow proprietary packages
  nixpkgs.config.allowUnfree = true;


  # Hardware and kernel

  hardware = {
    opengl.extraPackages = [ pkgs.intel-ocl ];
    pulseaudio.enable = true;
  };


  # Users

  users.users.sandydoo = {
    home = "/home/sandydoo";
    description = "Sander";
    extraGroups = [ "wheel" "networkmanager" "vboxsf" ];
    isNormalUser = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOWLadQ+eO8lQ5NdY5gUxi3EO6h2uIqp5HSVxPzx2gMGGQkZ1GIqpkeaA0RibrlyyoLA9wJvXvxgAXVQaQkdXhjkstvkxj7mwghgvs+TCE0PpYIWgL4AYqc5BLVR9EBZ8CBgE9dDdvdJ5J0cr63WXFgwaDClAXVaeUzHn8qnrbl0E5ExbQjxFtHYpUxrKnNmCWn+vmaNXQSiyarrTh0MiHwZ7pOuwFQq0ZTdIVV/FU6nS4Ci6E35s2N2FhMFzJFDlG/tGHXrI4OqCHfdfcNGBHEXh9C7QnQRiKIpGaTcBoUlY/a45Vt2RrEl9PgoGwBMcyax6P9O0UYIWoRpFiPay9wZVzy/QPYmgg38cfYF9BEmy8nsLoeaGASGd+xY+GRPWXBdXmgVglInONx9Io32tKe9lUQz7Tclsth87Cj5/llDKFGkqxyoERgKZ83APxRJMw/v4rzSda7sMS2qWggfb53OXXmsDDEqzKXkD7h5i/Vhnzl0xMRag5ebAJN2Vsv+xjlzMa/la3UFcvuOImn/DDCFgxifji+RCs84pu12787Hg38SrgyKB7sYZAnw9uRfaQR6wOjYVDo2jojDZ+PMDhAszjQnvgmz3rXdfxqDHIZcRvz9C8m2QJS00QWrz+Qlsn65qe3BGNvpQrGlYpIgjoPM+EGUqhazSpyeeFQDHk4w== hey@sandydoo.me"
    ];
    shell = pkgs.fish;
  };

  programs = {
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
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
    unstable.kakoune
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
