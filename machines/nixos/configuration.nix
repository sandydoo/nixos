{ config, lib, pkgs, unstable, inputs, nixpkgs, nix-unstable, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    ../../cachix.nix
  ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.systemd-boot.consoleMode = "0";

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  # systemd-boot.consoleMode "1" throws errors in VMWare
  hardware.video.hidpi.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.setLdLibraryPath = true;

  networking.hostName = "nixos";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.enp0s1 = {
    useDHCP = true;
    ipv4.addresses = [
      {
        address = "192.168.64.2";
        prefixLength = 24;
      }
    ];
  };
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-*" ];
  networking.nat.externalInterface = "enp0s1";

  networking.firewall.enable = false;

  networking.extraHosts = ''
    127.0.0.3 cachix-development.nixos
    127.0.0.4 api.nixos
  '';

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "br0" "virbr0" ];

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;
  # services.spice-webdavd.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  nix.package = unstable.nix;

  nix.registry = {
    stable.flake = inputs.nixpkgs;
    latest.flake = inputs.nix-unstable;
    nix-config.flake = inputs.self;
  };
  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "stable=${pkgs.path}"
    "latest=${unstable.path}"
  ];

  nix.settings.trusted-users = [ "root" "sandydoo" ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cachix-private.cachix.org-1:3axMmTI11ok4U2nMmWX8MZsRLmQzQBuRdOJ0EszhPuY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "loony-tools:pr9m4BkM/5/eSTZlkQyRt57Jz7OMBxNSUiMC4FkcNfk="
  ];

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cachix-private.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.iog.io"
    "https://cache.zw3rk.com"
  ];

  nix.settings.system-features = ["kvm" "big-parallel"];

  nix.extraOptions = ''
    keep-outputs = false
    keep-derivations = false
    min-free = ${toString (1024 * 1024 * 1024)}
    experimental-features = nix-command flakes
  '';

  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 180d";
  };

  # Allow proprietary packages.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnsupported = true;
  nixpkgs.overlays = [
    (import ../../overlays)
    (final: prev: { latest = unstable; })
  ];


  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.sandydoo = import "${inputs.self}/users/sandydoo/home.nix";

  users.mutableUsers = false;

  services.openssh = {
    enable = true;
    allowSFTP = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    extraConfig = ''
      StreamLocalBindUnlink yes
      AcceptEnv COLORTERM
    '';
  };

  services.sshd.enable = true;

  programs.ssh.extraConfig = ''
    SendEnv LANG LC_*
    SendEnv COLORTERM
  '';

  # See: https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  services.xserver = {
    enable = true;
    layout = "us";
    # dpi = 220;

    resolutions = [
      { x = 3840; y = 2160; }
    ];
  #   desktopManager.gnome.enable = true;
  #   displayManager = {
  #     gdm.enable = true;
  #     autoLogin = {
  #       enable = true;
  #       user = "sandydoo";
  #     };
  #   };
  #   # desktopManager.xterm.enable = false;

    displayManager = {
      defaultSession = "none+i3";
      lightdm.enable = true;
     
      sessionCommands = ''
        ${pkgs.xorg.xset}/bin/xset r rate 200 40
        ${pkgs.xorg.xrandr}/bin/xrandr -s '2880x1800'
      '';
    };
  #   # displayManager.autoLogin = {
  #   #   enable = false;
  #   #   user = "sandydoo";
  #   # };
  #   # displayManager.lightdm.enable = true;
  #   # # displayManager.lightdm.greeters.pantheon.enable = true;

  #   # windowManager.i3.enable = true;
  #   # windowManager.i3.package = pkgs.i3-gaps;
  #   # windowManager.i3.extraPackages = with pkgs; [ dmenu i3status ];
  };

  services.vscode-server.enable = true;
  services.lorri.enable = true;

  services.eternal-terminal.enable = true;
  programs.mosh.enable = true;
  programs.tmux.enable = true;
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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };
  programs._1password.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    let
      haskell-language-server-custom = pkgs.haskell-language-server.override {
        dynamic = true;
        supportedGhcVersions = [ "8107" "902" "924" "925" ];
      };
    in with pkgs; [
    home-manager
    cachix

    # Development
    gdb

    # Tools
    fd
    jq
    ripgrep
    killall
    xclip
    neofetch
    gparted
    ncdu

    # Graphics
    glxinfo
    ocl-icd
    clinfo
    # renderdoc

    xscreensaver

    # Editors
    vim
    kakoune
    helix

    # Version control
    git
    gh

    # Crypto
    gnupg
    pinentry-curses
    pinentry-gnome

    python3

    # JavaScript
    nodejs-16_x
    nodePackages.npm
    nodePackages.yarn
    nodePackages.vscode-json-languageserver

    # Nix
    nil

    # Haskell
    stack
    cabal-install
    ghc
    hlint
    ormolu
    haskell-language-server-custom

    # Elm
    elmPackages.elm
    elmPackages.elm-language-server
    elmPackages.elm-format

    # Lua (for neovim configs)
    latest.lua-language-server

    # google-chrome
    firefox

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

    # VM
    # Graphics driver for QEMU guests
    virglrenderer
    # xorg.xf86videovmware

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
