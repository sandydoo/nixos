{
  config,
  inputs,
  pkgs,
  lib,
  unstable,
  stable,
  isLinux,
  ...
}:

{
  boot.loader.timeout = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # The default mode "1" is not suppored by VMWare
  boot.loader.systemd-boot.consoleMode = "keep";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "mitigations=off" ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  hardware.enableAllFirmware = true;
  hardware.graphics.enable = true;

  networking.useNetworkd = lib.mkDefault false;
  networking.firewall.enable = lib.mkDefault true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nix.package = pkgs.nixVersions.latest;

  # Disable channels entirely.
  # Requires removing all the channel files and symlinks manually.
  # nix.channel.enable = false;

  nix.registry = {
    # Stable: pinned stable channel
    nixpkgs.flake = inputs.nixpkgs;
    stable.flake = inputs.nixpkgs;
    # Latest: pinned unstable channel
    latest.flake = inputs.nix-unstable;
    # Nightly: unpinned unstable
    nightly.to = {
      owner = "NixOS";
      ref = "nixpkgs-unstable";
      repo = "nixpkgs";
      type = "github";
    };
  };
  nix.nixPath =
    let
      inherit (config.nix) registry;
    in
    [
      "nixpkgs=${registry.nixpkgs.flake}"
      "stable=${registry.stable.flake}"
      "latest=${registry.latest.flake}"
    ];

  # Allow proprietary packages.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupported = true;
  nixpkgs.overlays = [
    (import "${inputs.self}/overlays")
    (final: prev: { latest = unstable; })
  ];

  nix.settings.trusted-users = [ "sandydoo" ];
  nix.settings.substituters = [
    "https://nix-community.cachix.org?priority=41"
  ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nix.settings.max-jobs = "auto";

  nix.extraOptions = ''
    always-allow-substitutes = true
    connect-timeout = 5
    experimental-features = nix-command flakes auto-allocate-uids
    keep-derivations = false
    keep-outputs = false
    log-lines = 30
    min-free = ${toString (1024 * 1024 * 1024)}
    show-trace = true
    warn-dirty = false
  '';

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  users.mutableUsers = false;

  services.dnsmasq = {
    enable = true;
    settings = {
      server = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      listen-address = "127.0.0.1";
      bind-interfaces = true;
      address = [
        "/nixos/127.0.0.1"
        "/cachix/127.0.0.1"
        "/cachix.internal/127.0.0.1"
      ];
    };
  };

  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings.KbdInteractiveAuthentication = false;
    settings.PasswordAuthentication = false;
    settings.PermitRootLogin = "no";
    settings.StreamLocalBindUnlink = "yes";
    settings.AcceptEnv = "COLORTERM";
  };

  programs.ssh.extraConfig = ''
    SendEnv LANG LC_*
    SendEnv COLORTERM
  '';

  # See: https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
  systemd.network.wait-online.enable = false;

  # Use restart instead of stop/start for network services.
  systemd.services.systemd-networkd.stopIfChanged = false;
  systemd.services.systemd-resolved.stopIfChanged = false;

  services.lorri.enable = true;

  services.eternal-terminal.enable = true;
  programs.mosh.enable = true;
  programs.fish.enable = true;
  programs._1password.enable = true;

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager

    # Development
    binutils
    gdb
    strace

    # Tools
    killall
    xclip # Copy to clipboard
    duf # Disk usage
    gparted
    ncdu

    # Graphics
    glxinfo
    ocl-icd
    clinfo
    # renderdoc

    # Crypto
    pinentry-curses

    firefox
    ungoogled-chromium

    # Networking
    openssl
    dnsutils
    nftables
    openvpn
    wireguard-tools

    # Clipboard
    gtkmm3
  ];

  # Let 'nixos-version --json' know about the Git revision
  # of this flake.
  system.configurationRevision = lib.mkIf (inputs.self ? rev) inputs.self.rev;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
