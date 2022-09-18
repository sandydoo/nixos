{ config, pkgs, unstable, nixpkgs, nix-unstable, ... }:

{
  # Include the results of the hardware scan.
  imports = [
    ./hardware-configuration.nix
    ../../cachix.nix
  ];
  
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  hardware.video.hidpi.enable = true;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.setLdLibraryPath = true;
  hardware.opengl.extraPackages = [ pkgs.intel-ocl ];

  networking.hostName = "superstrizh";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  # Disable the firewall for now.
  networking.firewall.enable = false;

  virtualisation.vmware.guest.enable = true;
  virtualisation.vmware.guest.headless = false;

  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  nix.package = unstable.nix;

  nix.registry.stable.flake = nixpkgs;
  nix.registry.latest.flake = nix-unstable;

  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cachix-private.cachix.org-1:3axMmTI11ok4U2nMmWX8MZsRLmQzQBuRdOJ0EszhPuY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
  ];

  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://cachix-private.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.iog.io"
  ];

  nix.extraOptions = ''
    keep-outputs = false
    keep-derivations = false
    min-free = ${toString (1024 * 1024 * 1024)}
    experimental-features = nix-command flakes
  '';

  nix.autoOptimiseStore = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 60d";
  };

  # Allow proprietary packages.
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;
  nixpkgs.overlays = [
    (import ../../overlays)
    (final: prev: { latest = unstable; })
  ];

  users.mutableUsers = false;

  services.openssh = {
    enable = true;
    allowSFTP = true;
    passwordAuthentication = false;
    permitRootLogin = "no";
    extraConfig = ''
      StreamLocalBindUnlink yes
    '';
  };

  services.sshd.enable = true;

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

  services.vscode-server.enable = true;

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
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    let
      haskell-language-server-custom = pkgs.haskell-language-server.override {
        dynamic = true;
        supportedGhcVersions = [ "8107" "902" "923" ];
      };
    in with pkgs; [
    home-manager
    cachix

    # Tools
    fd
    jq
    ripgrep
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
    kakoune

    # Version control
    git
    gh

    # Crypto
    gnupg
    pinentry-gnome

    python3

    # JavaScript
    nodejs
    nodePackages.npm
    nodePackages.yarn

    # Haskell
    stack
    cabal-install
    hlint
    ormolu
    haskell-language-server-custom

    google-chrome
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
    xorg.xf86videovmware
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
