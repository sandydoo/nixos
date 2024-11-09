{ config, pkgs, lib, nixpkgs, nix-unstable, ... }:

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

  pinentry-custom = pkgs.writeShellScriptBin "pinentry-custom" ''
    pinentry=${lib.getExe pkgs.pinentry-tty}
    case "$PINENTRY_USER_DATA" in
    *USE_TTY*)  pinentry=${lib.getExe pkgs.pinentry-tty} ;;
    *USE_CURSES*) pinentry=${lib.getExe pkgs.pinentry-curses} ;;
    ${lib.optionalString pkgs.stdenv.isLinux ''
    *USE_GNOME3*) pinentry=${lib.getExe pkgs.pinentry-gnome} ;;
    ''}
    ${lib.optionalString pkgs.stdenv.isDarwin ''
    *USE_MAC*) pinentry=${lib.getBin pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac ;;
    ''}
    esac
    exec $pinentry "$@"
  '';
in
{
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
    neovim
    helix
    lazygit

    awscli

    # Tools
    gnugrep
    htop
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
    pinentry-custom
    blackbox

    cmus
    ncmpcpp
    spotifyd

    xz
    lzip
    p7zip
    par2cmdline

    macfuse-stubs

    weechat
    # weechatScripts.weechat-matrix
    weechatScripts.weechat-go
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
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon = {
    enable = true;
    logFile = "/var/log/nix-daemon.log";
    tempDir = "/tmp";
  };
  launchd.daemons.nix-daemon.serviceConfig.SoftResourceLimits.NumberOfFiles = 1048576;

  nix.package = pkgs.nixVersions.nix_2_23;

  # Stable: pinned stable channel
  # nix.registry.nixpkgs.flake = nixpkgs;
  nix.registry.stable.flake = nixpkgs;
  # Latest: pinned unstable channel
  nix.registry.latest.flake = nix-unstable;
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

  # Do not enable sandboxing on macOS.
  # nix.useSandbox = false;
  # nix.sandboxPaths = [ "/System/Library/Frameworks" "/System/Library/PrivateFrameworks" "/usr/lib" "/usr/bin/env" "/private/tmp" "/private/var/tmp" ];

  nix.extraOptions = ''
    auto-optimise-store = false
    keep-derivations = false
    keep-outputs = false
    experimental-features = nix-command flakes
  '';
  nix.settings.trusted-users = [ "root" "sander" ];
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://nix-community.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  nix.linux-builder = {
    enable = true;
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
