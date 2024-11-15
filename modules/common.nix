{ config, inputs, pkgs, lib, unstable, ... }:

{
  boot.loader.timeout = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # The default mode "1" is not suppored by VMWare
  boot.loader.systemd-boot.consoleMode = "keep";

  # 6.11's oom-killer is very aggressive and kills nix-env.
  # https://discourse.nixos.org/t/linux-6-11-tends-to-kill-long-running-nix-operations-under-pressure/52824
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_6_11;
  boot.kernelParams = [ "mitigations=off" ];

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  hardware.enableAllFirmware = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.setLdLibraryPath = true;

  networking.useNetworkd = lib.mkDefault false;
  networking.firewall.enable = lib.mkDefault true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  nix.package = unstable.nixVersions.nix_2_23;

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
    let inherit (config.nix) registry;
    in [
    "nixpkgs=${registry.nixpkgs.flake}"
    "stable=${registry.stable.flake}"
    "latest=${registry.latest.flake}"
  ];

  nix.settings.trusted-users = [ "root" "sandydoo" ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
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
    options = "--delete-older-than 180d";
  };

  # Allow proprietary packages.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupported = true;
  nixpkgs.overlays = [
    (import "${inputs.self}/overlays")
    (final: prev: { latest = unstable; })
  ];

  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; inherit unstable; };
  home-manager.users.sandydoo = import "${inputs.self}/users/sandydoo/home.nix";

  users.mutableUsers = false;

  services.dnsmasq = {
    enable = true;
    settings = {
      server = [ "1.1.1.1" "1.0.0.1" ];
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
  programs.tmux.enable = true;
  programs.tmux.aggressiveResize = false;
  programs.tmux.plugins = with pkgs.tmuxPlugins; [
    sensible
    pain-control
    resurrect
    continuum
    sidebar
    prefix-highlight
    tmux-thumbs
  ];

  programs.fish.enable = true;
  programs._1password.enable = true;

  virtualisation.docker.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    home-manager
    cachix

    # Development
    binutils
    gdb
    strace

    # Tools
    fd                      # Find files
    jq                      # Handle JSON
    ripgrep                 # Replace grep
    killall
    xclip                   # Copy to clipboard
    neofetch
    duf                     # Disk usage
    gparted
    ncdu
    comma                   # Run programs without installing them

    # Graphics
    glxinfo
    ocl-icd
    clinfo
    # renderdoc

    # Editors
    vim
    kakoune

    # Version control
    git
    git-absorb              # git commit --fixup, but automatic
    gh                      # GitHub CLI

    # Crypto
    gnupg
    pinentry-curses

    # C
    gnumake
    gcc

    # Python
    python3
    python3.pkgs.black      # Format python code

    # JavaScript
    nodejs
    nodePackages.npm
    nodePackages.yarn
    nodePackages.vscode-json-languageserver

    # TypeScript
    nodePackages.typescript
    nodePackages.typescript-language-server

    # Nix
    nil
    nix-prefetch
    nix-output-monitor

    # Shell
    shfmt                   # Format shell scripts

    # Haskell
    latest.stack
    latest.cabal-install
    latest.ghc
    latest.hlint
    latest.ormolu
    latest.haskell-language-server

    # Elm
    elmPackages.elm
    elmPackages.elm-language-server
    elmPackages.elm-format

    # Lua (for neovim configs)
    latest.lua-language-server
    # To auto-install tree-sitter parsers
    latest.tree-sitter

    firefox
    ungoogled-chromium

    # Send files
    croc

    # Networking
    mtr
    iperf3
    dogdns
    openssl
    dnsutils
    nftables
    openvpn
    wireguard-tools

    # Clipboard
    gtkmm3

    (writeShellScriptBin "xrandr-auto" ''
      xrandr --output Virtual-1 --auto
    '')
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

