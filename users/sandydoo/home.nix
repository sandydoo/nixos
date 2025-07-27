{ pkgs, lib, inputs, isLinux, ... }:

{
  imports = [
    inputs.vscode-server.homeModules.default
    inputs.nix-index-database.homeModules.nix-index
  ]
  ++ lib.optional isLinux ./systems/linux.nix
  ++ lib.optional (!isLinux) ./systems/darwin.nix;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Editors
    neovim
    kakoune
    helix

    # Neovim
    lua         # Required by luarocks
    luarocks    # Lua package manager (required by lazy.nvim)

    # Terminal
    vivid         # Set terminal colors with LS_COLORS

    # For git difftool
    difftastic

    # AI
    latest.claude-code

    # Node
    volta

    # Nix
    nix-output-monitor

    # Rust
    cargo-outdated
    cargo-sweep
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.zellij = {
    enable = false;
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
      copy_command = if isLinux then "wl-copy" else "pb-copy";
    };
  };

  # Disable this helper script on flake-based machines.
  # programs.command-not-found.enable = false;

  # Indexed search of files in nixpkgs
  programs.nix-index.enable = true;
  programs.nix-index.enableBashIntegration = true;
  programs.nix-index.enableFishIntegration = true;
  # Integrate nix-index-database with comma.
  # Allows directly running binaries by name without installing or setting up a shell.
  programs.nix-index-database.comma.enable = true;

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
    ignores = [ (builtins.readFile ./git/gitignore) ];
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

  programs.tmux.enable = true;
  programs.tmux.aggressiveResize = false;
  programs.tmux.plugins = with pkgs.tmuxPlugins; [
    sensible
    pain-control
    resurrect
    continuum
    sidebar
    prefix-highlight
    tmux-thumbs
  ];
  programs.tmux.extraConfig = builtins.readFile ./tmux/tmux.conf;

  # Sync files between machines
  services.syncthing.enable = false;
}
