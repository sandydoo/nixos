{ pkgs, lib, ... }:

let
  inherit (lib.hm.gvariant) mkUint32;
in
{
  home.packages = [
  ];

  dconf.settings = {
    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 0;
    };
  };

  # xsession.enable = true;
  # xsession.initExtra = ''
  #   ${pkgs.xscreensaver}/bin/xscreensaver -no-splash &
  # '';

  xresources.extraConfig = ''
    ! URXVT FONT SETTINGS
    !------------------------------------------------
    Xft.dpi: 180
    Xft.autohint: true
    Xft.antialias: true
    Xft.hinting: true
    Xft.hintstyle: hintslight
    Xft.rgba: rgb
    Xft.lcdfilter: lcddefault
    xterm*faceName: monospace:pixelsize=18
  '';

  home.file.".config/sway/config".source = ../sway;

  services.xscreensaver.enable = false;
  services.xscreensaver.settings.mode = "blank";

  programs.rofi.enable = true;

  programs.i3status = {
    enable = true;

    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };

    modules = {
      ipv6.enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  services.picom.enable = false;
  services.picom.settings = ''
    corner-radius: 15;
  '';
  # services.polybar.enable = true;
  # services.polybar.script = "polybar bar &";

  programs.ghostty.enable = true;

  programs.firefox = {
    enable = true;
    profiles.sandydoo.settings = {
      "browser.startup.homepage" = "https://duckduckgo.com/";
      "browser.search.region" = "GB";
      "general.useragent.locale" = "en-GB";
    };
  };

  programs.vscode.enable = true;
  # Workaround for https://github.com/nix-community/home-manager/issues/2798
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.profiles.default.extensions = with pkgs.vscode-extensions; [
    ms-vscode-remote.remote-ssh
  ];

  services.vscode-server.enable = true;
  services.vscode-server.enableFHS = false;
  services.vscode-server.installPath = "$HOME/.vscode-server";

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = ../hey-at-sandydoo.me.public.asc;
        trust = "ultimate";
      }
    ];
    settings = {
      keyserver = "hkps://keys.openpgp.org";
      # Use ASCII armored output instead of binary
      armor = true;
      # Show key IDs in 16-character format
      keyid-format = "0xlong";
      default-key = "F4869E8B85ED07AC611E2EAF171257C9C397032E";

      # Agent settings
      use-agent = true;
      no-autostart = true;
    };
  };

  home.stateVersion = "22.11";
}
