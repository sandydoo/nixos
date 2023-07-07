{ pkgs, lib, inputs, ... }:

with lib.hm.gvariant;

{
  imports = [
    inputs.vscode-server.homeModules.default
  ];

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Editors
    neovim-nightly
    kakoune
    helix

    # Terminal
    vivid         # Set terminal colors with LS_COLORS
  ];

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

  home.file.".config/sway/config".source = ./sway;

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

  home.sessionVariables = { EDITOR = "nvim"; };

  # Disable this helper script on flake-based machines.
  # programs.command-not-found.enable = false;
  programs.nix-index.enable = true;
  programs.nix-index.enableBashIntegration = true;
  programs.nix-index.enableFishIntegration = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  home.file.".config/direnv/direnv.toml".text = ''
    [global]
    strict_env = true
    warn_timeout = "1h"
  '';

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

  programs.bash.enable = true;

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -x LS_COLORS (vivid generate gruvbox-light)
      . $HOME/.homesick/repos/homeshick/homeshick.fish
      source "$HOME/.homesick/repos/homeshick/completions/homeshick.fish"

      # Integrate with iTerm2
      test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

    '';
    plugins = [{
      name = "pure";
      src = pkgs.fetchFromGitHub {
        owner = "pure-fish";
        repo = "pure";
        rev = "v4.4.1";
        sha256 = "sha256-2b2/LZXSchHnPKyjwAcR/oCY38qJ/7Dq8cJHrJmdjoc=";
      };
    }];
  };

  programs.git = {
    enable = true;
    userName = "Sander";
    userEmail = "hey@sandydoo.me";
    signing = {
      key = "D1A763BC84F34603";
      signByDefault = true;
    };
    extraConfig = {
      alias = {
        last = "log -1 HEAD";
        graph = "log --graph --format='%C(auto) %h %s'";
        p = "switch -";
        st = "status";
        staged = "diff --staged";
        undo = "reset HEAD~";
        unstage = "reset HEAD --";
      };
      branch.autoSetupRebase = "always";
      core = {
        editor = "nvim";
        quotepath = "off";
      };
      init.defaultBranch = "main";
      merge.ff = "no";
      pull.ff = "only";
      push.default = "current";
      tag.gpgSign = true;
    };
    ignores = [ ".DS_Store" ".nlsp-settings" ];
  };

  programs.git.difftastic.enable = true;

  programs.vscode.enable = true;
  # Workaround for https://github.com/nix-community/home-manager/issues/2798
  programs.vscode.mutableExtensionsDir = false;
  programs.vscode.extensions = with pkgs.vscode-extensions;
    [ ms-vscode-remote.remote-ssh ];

  services.vscode-server.enable = true;
  services.vscode-server.enableFHS = false;
  services.vscode-server.installPath = "~/.vscode-server-insiders";

  programs.gpg.enable = true;
  programs.gpg.publicKeys = [
    { source = ./hey-at-sandydoo.me.public.asc;
      trust = "ultimate";
    }
  ];
  programs.gpg.settings = {
    # Use ASCII armored output instead of binary
    armor = true;

    # Show key IDs in 16-character format
    keyid-format = "0xlong";

    keyserver = "hkps://keys.openpgp.org";

    use-agent = true;

    default-key = "F4869E8B85ED07AC611E2EAF171257C9C397032E";

    no-autostart = true;
  };

  services.gpg-agent.enable = true;

  programs.bat.enable = true;

  programs.exa = {
    enable = true;
    enableAliases = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Sync files between machines
  services.syncthing.enable = false;

  home.stateVersion = "22.11";
}
