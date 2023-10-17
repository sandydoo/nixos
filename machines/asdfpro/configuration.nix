{ config, pkgs, nixpkgs, nix-unstable, ... }:

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
    nixfmt
    cachix

    abduco
    mosh
    dtach
    eternal-terminal

    bat
    broot
    exa
    duf
    du-dust
    fd
    fzf
    jq
    ripgrep
    tldr

    pandoc

    gnupg
    pinentry
    pinentry_mac
    blackbox

    cmus
    ncmpcpp
    spotifyd
    spotify-tui

    xz
    lzip
    p7zip
    par2cmdline

    macfuse-stubs

    weechat
    weechatScripts.weechat-matrix
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
    nodePackages.vscode-langservers-extracted

    # Image manipulation
    imagemagick

    # Videos
    yt-dlp
    streamlink
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon = {
    enable = true;
    logFile = "/var/log/nix-daemon.log";
    tempDir = "/tmp";
  };
  launchd.daemons.nix-daemon.serviceConfig.SoftResourceLimits.NumberOfFiles = 1048576;

  nix.package = pkgs.nixVersions.nix_2_16;

  # Stable: pinned stable channel
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
    "https://cachix-private.cachix.org"
    "https://nix-community.cachix.org"
    "https://cache.iog.io"
    "https://iohk.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
    "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    "cachix-private.cachix.org-1:3axMmTI11ok4U2nMmWX8MZsRLmQzQBuRdOJ0EszhPuY="
    "hercules-ci.cachix.org-1:ZZeDl9Va+xe9j+KqdzoBZMFJHVQ42Uu/c/1/KMC5Lw0="
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  programs.zsh.enable = true;
  programs.fish.enable = true;
  # Work around incorrect order in PATH. These paths need to come before
  # the system ones.
  # https://github.com/LnL7/nix-darwin/issues/122
  programs.fish.loginShellInit = ''
    fish_add_path --move --prepend --path /run/current-system/sw/bin /nix/var/nix/profiles/default/bin

    # Add UTM and utmctl commands
    fish_add_path /Applications/UTM.app/Contents/MacOS/
  '';

  programs.nix-index.enable = true;

  security.pam.enableSudoTouchIdAuth = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
