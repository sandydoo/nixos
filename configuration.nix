{ config, pkgs, lib, nixpkgs, nix-unstable, unstable, ... }:

with lib;

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "sandydoo";

  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;

  # Nix store

  nix.package = unstable.nix;

  nix.registry.nixpkgs.flake = nixpkgs;
  nix.registry.unstable.flake = nix-unstable;

  nix.binaryCaches = [
    "https://cache.nixos.org"
    "https://hydra.iohk.io"
    "https://iohk.cachix.org"
    "https://nix-community.cachix.org"
  ];
  nix.binaryCachePublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nix.autoOptimiseStore = true;

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

  hardware.video.hidpi.enable = true;
  hardware.pulseaudio.enable = true;

  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.setLdLibraryPath = true;
  hardware.opengl.extraPackages = [ pkgs.intel-ocl ];

  security.sudo.wheelNeedsPassword = false;

  # Users

  users.mutableUsers = false;

  users.users.sandydoo = {
    home = "/home/sandydoo";
    description = "Sander";
    extraGroups = [ "wheel" ];
    isNormalUser = true;
    createHome = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDOWLadQ+eO8lQ5NdY5gUxi3EO6h2uIqp5HSVxPzx2gMGGQkZ1GIqpkeaA0RibrlyyoLA9wJvXvxgAXVQaQkdXhjkstvkxj7mwghgvs+TCE0PpYIWgL4AYqc5BLVR9EBZ8CBgE9dDdvdJ5J0cr63WXFgwaDClAXVaeUzHn8qnrbl0E5ExbQjxFtHYpUxrKnNmCWn+vmaNXQSiyarrTh0MiHwZ7pOuwFQq0ZTdIVV/FU6nS4Ci6E35s2N2FhMFzJFDlG/tGHXrI4OqCHfdfcNGBHEXh9C7QnQRiKIpGaTcBoUlY/a45Vt2RrEl9PgoGwBMcyax6P9O0UYIWoRpFiPay9wZVzy/QPYmgg38cfYF9BEmy8nsLoeaGASGd+xY+GRPWXBdXmgVglInONx9Io32tKe9lUQz7Tclsth87Cj5/llDKFGkqxyoERgKZ83APxRJMw/v4rzSda7sMS2qWggfb53OXXmsDDEqzKXkD7h5i/Vhnzl0xMRag5ebAJN2Vsv+xjlzMa/la3UFcvuOImn/DDCFgxifji+RCs84pu12787Hg38SrgyKB7sYZAnw9uRfaQR6wOjYVDo2jojDZ+PMDhAszjQnvgmz3rXdfxqDHIZcRvz9C8m2QJS00QWrz+Qlsn65qe3BGNvpQrGlYpIgjoPM+EGUqhazSpyeeFQDHk4w== hey@sandydoo.me"
    ];
    shell = pkgs.fish;
  };

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [ inter ibm-plex fira-code ];
  };

  services.xrdp.enable = true;
  services.xrdp.openFirewall = true;
  services.xrdp.defaultWindowManager = "i3";

  programs.mosh.enable = true;
  services.eternal-terminal.enable = true;
  services.code-server.enable = true;
  services.code-server.auth = "none";
  services.code-server.user = "sandydoo";

  programs = {
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 config.services.eternal-terminal.port ];
  };

  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  services = {
    openssh = {
      enable = true;
      allowSFTP = true;
      passwordAuthentication = false;
      permitRootLogin = "no";
      extraConfig = ''
        StreamLocalBindUnlink yes
      '';
    };
    sshd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    home-manager

    # Shell
    fish

    # Tools
    fd
    jq
    xclip
    neofetch
    gparted

    # Graphics
    glxinfo
    ocl-icd
    clinfo
    renderdoc

    xscreensaver

    # Editors
    vim
    unstable.kakoune

    # Version control
    git
    unstable.gh

    # Crypto
    gnupg
    pinentry-gnome

    python3

    # JavaScript
    nodejs
    nodePackages.npm
    nodePackages.yarn

    google-chrome
    firefox

    # Send files
    croc

    # Networking
    iperf3
    dogdns
    openssl
    dnsutils
    nftables
    openvpn
    wireguard-tools

    # VM
    xorg.xf86videovmware
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database vers>
  # on your system were taken. It‘s perfectly fine and recommended to>
  # this value at the release version of the first install of this sy>
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options>
  system.stateVersion = "21.11"; # Did you read the comment?
}
