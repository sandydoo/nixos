{ pkgs, lib, ... }:

with lib.hm.gvariant;

{
  programs.home-manager.enable = true;

  # home.packages = with pkgs; [
  #   gnome3.gnome-tweak-tool
  #   gnomeExtensions.appindicator
  #   gnomeExtensions.dash-to-dock
  #   gnome.dconf-editor
  # ];

  # dconf.settings = {
  #     "org/gnome/desktop/session" = {
  #         "idle-delay" = mkUint32 0;
  #     };
  # };

  # xsession.enable = true;
  # xsession.initExtra = ''
  #   ${pkgs.xscreensaver}/bin/xscreensaver -no-splash &
  # '';

  services.xscreensaver.enable = true;
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
  services.picom.extraOptions = ''
    corner-radius: 15;
  '';
  # services.polybar.enable = true;
  # services.polybar.script = "polybar bar &";

  home.sessionVariables = { EDITOR = "kak"; };

  # Disable this helper script on flake-based machines.
  # programs.command-not-found.enable = false;
  programs.nix-index.enable = true;
  programs.nix-index.enableBashIntegration = true;
  programs.nix-index.enableFishIntegration = true;

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
    plugins = [{
      name = "pure";
      src = pkgs.fetchFromGitHub {
        owner = "pure-fish";
        repo = "pure";
        rev = "v3.5.0";
        sha256 = "0nr97z138v93lmvi4zh4h09gi5mzaxk4j6rk4x3calk0vjgfw7qs";
      };
    }];
  };

  programs.git = {
    enable = true;
    userName = "sandydoo";
    userEmail = "hey@sandydoo.me";
    signing = {
      key = "D1A763BC84F34603";
      signByDefault = true;
    };
    extraConfig = {
      core = {
        editor = "kak";
        quotepath = "off";
      };
      init.defaultBranch = "main";
      pull.ff = "simple";
      push.default = "simple";
    };
    ignores = [ ".DS_Store" ];
  };

  programs.vscode.enable = true;
  programs.vscode.extensions = with pkgs;
    [ vscode-extensions.ms-vscode-remote.remote-ssh ];

  programs.gpg.enable = true;
  programs.gpg.settings = {
    # Use ASCII armored output instead of binary
    armor = true;

    # Show key IDs in 16-character format
    keyid-format = "0xlong";

    keyserver = "hkps://keys.openpgp.org";
    use-agent = true;
  };

  programs.bat.enable = true;

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
