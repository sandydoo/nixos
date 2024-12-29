{ pkgs, lib, inputs, unstable, isLinux, ... }:

{
  imports = [
    inputs.vscode-server.homeModules.default
  ]
  ++ lib.optional isLinux ./systems/linux.nix
  ++ lib.optional (!isLinux) ./systems/darwin.nix;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Editors
    unstable.neovim
    kakoune
    helix

    # Terminal
    vivid         # Set terminal colors with LS_COLORS

    # For git difftool
    difftastic
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.zellij = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      theme = "catppuccin-macchiato";
      # Remove arrows
      simplified_ui = true;
      default_layout = "compact";
      ui = {
        pane_frames.rounded_corners = true;
        pane_frames.hide_session_name = true;
      };
    };
  };

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
    hide_env_diff = true
  '';

  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = true;

    character = {
      success_symbol = "[➜](bold green)";
    };

    aws = {
      disabled = true;
    };
  };

  programs.bash.enable = true;

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
        dft = "difftool";
        last = "log -1 HEAD";
        graph = "log --graph --format='%C(auto) %h %s'";
        p = "switch -";
        st = "status";
        staged = "diff --staged";
        undo = "reset HEAD~";
        unstage = "reset HEAD --";
      };
      branch = {
        autoSetupMerge = "simple";
        autoSetupRebase = "always";
      };
      core = {
        editor = "nvim";
        quotepath = "off";
      };
      credential.helper = lib.optionalString (!isLinux) "osxkeychain";
      diff.tool = "difftastic";
      difftool.prompt = false;
      difftool.difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
      init.defaultBranch = "main";
      merge.ff = "no";
      pager.difftool = true;
      pull.ff = "only";
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      tag.gpgSign = true;
    };
    ignores = [ ".DS_Store" ".nlsp-settings" ];
  };

  programs.bat.enable = true;
  programs.bat.config = {
    theme = "ansi";
  };

  programs.eza.enable = true;

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  # Sync files between machines
  services.syncthing.enable = false;
}
