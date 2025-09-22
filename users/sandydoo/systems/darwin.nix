{
  pkgs,
  unstable,
  lib,
  ...
}:

let
  pinentry-custom = pkgs.writeShellScriptBin "pinentry-custom" ''
    pinentry=${lib.getExe pkgs.pinentry-tty}
    case "$PINENTRY_USER_DATA" in
    *USE_TTY*) pinentry=${lib.getExe pkgs.pinentry-tty} ;;
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
  home.packages = [
    pinentry-custom
    pkgs.macmon # Monitor macOS system stats

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
