{
  config,
  pkgs,
  unstable,
  lib,
  ...
}:

let
  metalToolchain = pkgs.requireFile {
    name = "Metal.xctoolchain";
    sha256 = "sha256-dO1ls/R4BaxmCufwH6hhY+9n1y/6eqzvVJytX4e5vik=";
    hashMode = "recursive";
    message = ''
      Download Metal Toolchain 27A266a using Xcode 27.1:
        DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadComponent MetalToolchain
      Add the mounted Metal.xctoolchain directory to the Nix store:
        nix-store --add-fixed --recursive sha256 /path/to/Metal.xctoolchain
    '';
  };

  # FFmpeg expects the Metal tools in Xcode's pre-26 directory layout.
  ffmpegMetalTools = pkgs.runCommand "ffmpeg-metal-tools-27A266a" { } ''
    mkdir -p "$out/Contents/Developer/Toolchains"
    ln -s ${metalToolchain} "$out/Contents/Developer/Toolchains/XcodeDefault.xctoolchain"
  '';

  ffmpeg =
    (pkgs.ffmpeg-full.override {
      withUnfree = true;
      withMetal = true;
      xcode = ffmpegMetalTools;
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          # Fix a double release when yadif_videotoolbox drains its autorelease pool.
          (pkgs.fetchurl {
            name = "ffmpeg-metal-autorelease.patch";
            url = "https://code.ffmpeg.org/FFmpeg/FFmpeg/pulls/23850.patch";
            hash = "sha256-j9FIwwKkb6WjpyDI5eev1qXyzjK/93UtSOmddSXYkyc=";
          })
        ];
      });

  pinentry-custom = pkgs.writeShellScriptBin "pinentry-custom" ''
    pinentry=${lib.getExe pkgs.pinentry-tty}
    case "$PINENTRY_USER_DATA" in
    *USE_TTY*) pinentry=${lib.getExe pkgs.pinentry-tty} ;;
    *USE_CURSES*) pinentry=${lib.getExe pkgs.pinentry-curses} ;;
    ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
      *USE_GNOME3*) pinentry=${lib.getExe pkgs.pinentry-gnome} ;;
    ''}
    ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      *USE_MAC*) pinentry=${lib.getBin pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac ;;
    ''}
    esac
    exec $pinentry "$@"
  '';
in
{
  imports = [ ../../../modules/darwin/secretspec.nix ];

  secretspec = {
    enable = true;
    file = ../../../secretspec.toml;
    profile = "default";

    secrets.privateSshConfig = {
      name = "SSH_PRIVATE_CONFIG";
      path = "${config.home.homeDirectory}/.ssh/private/private.config";
      lifetime = "persistent";
      mode = "0600";
    };

    secrets.cachixSshConfig = {
      name = "SSH_CACHIX_CONFIG";
      path = "${config.home.homeDirectory}/.ssh/private/cachix.config";
      lifetime = "persistent";
      mode = "0600";
    };
  };

  home.packages = [
    pinentry-custom
    ffmpeg
    pkgs.chromaprint # fpcalc audio fingerprinting CLI
    pkgs.macmon # Monitor macOS system stats
    pkgs.xdr-boost # Boost XDR display brightness to 1600 nits

    # Apple containers
    unstable.container
  ];

  home.file.".hammerspoon/init.lua".source = ../hammerspoon/init.lua;

  home.sessionVariables = {
    VOLTA_HOME = "$HOME/.volta";
  };

  home.sessionPath = [
    "$VOLTA_HOME/bin"
  ];

  home.stateVersion = "24.11";
}
