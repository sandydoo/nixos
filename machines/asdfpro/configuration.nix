{ config, pkgs, lib, inputs, nixpkgs, nix-unstable, unstable, isLinux, ... }:

let
  typescript-language-server = pkgs.symlinkJoin {
    name = "typescript-language-server";
    paths = [ pkgs.nodePackages.typescript-language-server ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/typescript-language-server \
        --add-flags --tsserver-path=${pkgs.nodePackages.typescript}/lib/node_modules/typescript/lib/
    '';
  };

in
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; inherit unstable; inherit isLinux; };
  home-manager.users.sander = import "${inputs.self}/users/sandydoo/home.nix";
  users.users.sander.home = "/Users/sander";

  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gh
    act
    difftastic
    neofetch

    starship
    tmux
    kakoune
    kak-lsp
    helix
    lazygit

    awscli

    # Tools
    gnugrep
    btop
    procs
    bandwhich
    iperf3
    nmap
    netcat
    mkcert
    rsync
    rclone
    croc
    watchman
    entr
    direnv
    nix-direnv
    lorri
    nixpkgs-fmt
    nixfmt-rfc-style
    cachix
    comma                   # Run programs without installing them

    abduco
    mosh
    dtach
    eternal-terminal

    bat
    broot
    eza
    duf
    du-dust
    fd
    fzf
    jq
    ripgrep
    tldr

    pandoc

    gnupg
    blackbox

    cmus
    ncmpcpp
    spotifyd

    xz
    lzip
    p7zip
    par2cmdline

    macfuse-stubs

    irssi
    tiny

    cmatrix
    pastel

    # Nix
    nil

    # Haskell
    cabal-install
    stack
    ghc
    haskell-language-server
    cabal2nix
    ormolu
    stylish-haskell

    # Elm
    elmPackages.elm
    elmPackages.elm-language-server
    elmPackages.elm-test
    elmPackages.elm-format

    # Python
    python3

    # Rust
    rust-analyzer
    zld
    # mold

    # TypeScript
    nodejs
    nodePackages.typescript
    typescript-language-server

    # Lua
    latest.lua-language-server

    # JSON
    # https://github.com/NixOS/nixpkgs/issues/335533
    latest.nodePackages.vscode-langservers-extracted

    # Image manipulation
    imagemagick

    # Videos
    yt-dlp
    streamlink
  ];

  environment.variables = {
    EDITOR = "nvim";
    # Fix ghostty shell integration: https://github.com/ghostty-org/ghostty/discussions/2832
    XDG_DATA_DIRS = ["$GHOSTTY_SHELL_INTEGRATION_XDG_DIR"];
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon = {
    enable = true;
    logFile = "/var/log/nix-daemon.log";
    tempDir = "/tmp";
  };
  launchd.daemons.nix-daemon.serviceConfig.SoftResourceLimits.NumberOfFiles = 1048576;

  # Allow larger sandbox profiles
  # https://github.com/NixOS/nix/pull/12570
  nix.package = pkgs.nixVersions.nix_2_26.overrideAttrs (_: {
    src = pkgs.fetchFromGitHub {
      owner = "NixOS";
      repo = "nix";
      rev = "2.26-maintenance";
      sha256 = "sha256-lac6GvOJN5J4pkheRtjn3UraxITYwKUoYPzilJQCM4w=";
    };
  });

  # Stable: pinned stable channel
  # nix.registry.nixpkgs.flake = nixpkgs;
  nix.registry.stable.flake = inputs.nixpkgs;
  # Latest: pinned unstable channel
  nix.registry.latest.flake = inputs.nix-unstable;
  # Nightly: unpinned unstable
  nix.registry.nightly.to = {
    owner = "NixOS";
    ref = "nixpkgs-unstable";
    repo = "nixpkgs";
    type = "github";
  };
  # Only for legacy channel stuff, i.e. <nixpkgs>
  nix.nixPath = [
    "nixpkgs=${config.nix.registry.stable.flake}"
    "stable=${config.nix.registry.stable.flake}"
    "latest=${config.nix.registry.latest.flake}"
  ];

  # Periodically run the store optimizer.
  # auto-optimise-store is known to corrupt the store.
  nix.optimise.automatic = true;

  # Enable garbage collection.
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 1;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  nix.extraOptions = ''
    auto-optimise-store = false
    keep-derivations = false
    keep-outputs = false
    experimental-features = nix-command flakes
    darwin-log-sandbox-violations = true
  '';

  #Try enabling sandboxing on macOS.
  nix.settings.sandbox = "relaxed";

  nix.settings.trusted-users = [ "sander" ];
  nix.settings.substituters = [
    "https://nix-community.cachix.org?priority=41"
  ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  nix.buildMachines = [{
    hostName = "nixos-vmware";
    sshUser = "builder";
    sshKey = "/etc/nix/builder_ed25519";
    publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUQ3V1pUYjliUjRJUG9kbnhESXZDVkxwZjg3UWpSdFNZQ1pYc1kvdVBVdTMgcm9vdEBuaXhvcwo=";
    maxJobs = 4;
    protocol = "ssh-ng";
    speedFactor = 1;
    supportedFeatures = [ "kvm" "benchmark" "big-parallel" "nixos-test" ];
    systems = [ "aarch64-linux" "x86_64-linux" ];
  }];

  nix.linux-builder = {
    enable = false;
    maxJobs = 4;
    supportedFeatures = [ "kvm" "benchmark" "big-parallel" "nixos-test" ];
    config = { lib, ... }: {
      # A small set of builder options are available
      # virtualisation.darwin-builder.memorySize = 8 * 1024;

      virtualisation.cores = 4;
      virtualisation.memorySize = lib.mkForce (8 * 1024);
    };
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  # Work around incorrect order in PATH. These paths need to come before
  # the system ones.
  # https://github.com/LnL7/nix-darwin/issues/122
  programs.fish.loginShellInit = ''
    fish_add_path --move --prepend --path /run/current-system/sw/bin /nix/var/nix/profiles/default/bin

    # Add UTM and utmctl commands
    fish_add_path /Applications/UTM.app/Contents/MacOS/

    set -x PINENTRY_USER_DATA "USE_MAC=1"
  '';

  programs.nix-index.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
