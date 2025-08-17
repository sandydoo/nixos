{ pkgs, lib, ... }:

let
  inherit (lib.hm.gvariant) mkUint32;
in
{
  home.packages = with pkgs; [
    ghostty
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

  programs.kitty.enable = true;
  programs.alacritty.enable = true;
  programs.alacritty.settings = {
    import = [ "/etc/nixos/alacritty/ayu_dark.yaml" ];
    window = {
      padding.x = 5;
      padding.y = 5;
    };

    # font = {
    #   normal = {
    #     family = "";
    #     style = "Regular";
    #   };
    #   bold = {
    #     family = "IBM Plex Mono";
    #     style = "Bold";
    #   };
    #   italic = {
    #     family = "IBM Plex Mono";
    #     style = "Italic";
    #   };
    #   bold_italic = {
    #     family = "IBM Plex Mono";
    #     style = "Bold Italic";
    #   };
    #   size = 8.0;
    # };

    live_config_reload = true;
  };

  programs.firefox = {
    enable = true;
    profiles.sandydoo.settings = {
      "browser.startup.homepage" = "https://duckduckgo.com/";
      "browser.search.region" = "GB";
      "general.useragent.locale" = "en-GB";
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -x LS_COLORS (vivid generate gruvbox-light)

      # Integrate with iTerm2
      test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

      if test -n "$SSH_CLIENT"
        set -x PINENTRY_USER_DATA USE_CURSES=1
      end
    '';
    plugins = [
      {
        name = "pure";
        src = pkgs.fishPlugins.pure.src;
      }
      {
        name = "fish-abbreviation-tips";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fish-abbreviation-tips";
          rev = "v0.7.0";
          sha256 = "sha256-F1t81VliD+v6WEWqj1c1ehFBXzqLyumx5vV46s/FZRU=";
        };
      }
    ];
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
