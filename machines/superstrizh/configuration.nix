{ config, pkgs, inputs, unstable, nixpkgs, nix-unstable, ... }:

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

  # systemd-boot.consoleMode "1" throws errors in VMWare
  hardware.video.hidpi.enable = false;
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.setLdLibraryPath = true;
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

  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  virtualisation.libvirtd.allowedBridges = [ "br0" "virbr0" ];
  programs.dconf.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Don’t require password for sudo.
  security.sudo.wheelNeedsPassword = false;

  nix.package = unstable.nix;

  nix.registry.stable.flake = nixpkgs;
  nix.registry.latest.flake = nix-unstable;
  nix.nixPath = [
    "nixpkgs=${pkgs.path}"
    "stable=${pkgs.path}"
    "latest=${unstable.path}"
  ];

  nix.settings.trusted-users = [ "root" "@wheel" ];

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

  nix.settings.system-features = [ "big-parallel" "kvm" "nixos-test" ];

  nix.extraOptions = ''
    keep-outputs = false
    keep-derivations = false
    min-free = ${toString (1024 * 1024 * 1024)}
    experimental-features = nix-command flakes
  '';

  nix.settings.auto-optimise-store = true;
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

  programs.ssh.extraConfig = ''
    SendEnv LANG LC_*
    SendEnv COLORTERM
  '';

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
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages =
    let
      haskell-language-server-custom = pkgs.haskell-language-server.override {
        dynamic = true;
        supportedGhcVersions = [ "8107" "902" "924" "925" ];
      };

      typescript-language-server = pkgs.symlinkJoin {
        name = "typescript-language-server";
        paths = [ pkgs.nodePackages.typescript-language-server ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/typescript-language-server \
            --add-flags --tsserver-path=${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib/
        '';
      };
    in with pkgs; [
    home-manager
    cachix

    # Tools
    killall
    fd
    jq
    ripgrep
    xsel
    neofetch
    gparted
    ncdu

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

    # C
    gnumake
    cmake
    gcc

    # Python
    python3

    # JavaScript
    nodejs
    nodePackages.npm
    nodePackages.yarn

    # TypeScript
    nodePackages.typescript
    typescript-language-server

    # Lua
    latest.lua-language-server

    # JSON
    nodePackages.vscode-langservers-extracted

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
    virt-manager
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}
