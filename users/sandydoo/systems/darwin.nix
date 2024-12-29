{ pkgs, lib, ... }:

let
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
  home.packages = [ pinentry-custom ];

  home.file.".hammerspoon/init.lua".source = ../hammerspoon/init.lua;

  home.sessionVariables = {
    VOLTA_HOME = "$HOME/.volta";
  };

  home.sessionPath = [
    "$VOLTA_HOME/bin"
  ];

  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;

    # Effectively disable cache expiry
    defaultCacheTtl = 34560000;
    defaultCacheTtlSsh = 34560000;
    maxCacheTtl = 34560000;
    maxCacheTtlSsh = 34560000;

    sshKeys = [
      "FB9E85EC1136B7841BCAADDEDF430EB22F3F90E3"
    ];

    extraConfig = ''
      allow-loopback-pinentry
      pinentry-program ${toString pinentry-custom}/bin/pinentry-custom
    '';
  };

  home.stateVersion = "24.11";
}
