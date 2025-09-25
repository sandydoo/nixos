{
  pkgs,
  lib,
  inputs,
  isLinux,
  isDarwin,
  ...
}:

{
  imports = [
    inputs.vscode-server.homeModules.default
    inputs.nix-index-database.homeModules.nix-index
  ]
  ++ lib.optional isLinux ./systems/linux.nix
  ++ lib.optional (isDarwin) ./systems/darwin.nix;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Editors
    neovim
    kakoune
    kak-lsp
    helix

    # Neovim
    lua # Required by luarocks
    luarocks # Lua package manager (required by lazy.nvim)
    latest.lua-language-server

    # To auto-install tree-sitter parsers
    latest.tree-sitter

    # Terminal
    vivid # Set terminal colors with LS_COLORS

    # AI
    latest.claude-code
    latest.amp-cli

    # Node
    nodejs
    nodePackages.typescript
    typescript-language-server
    volta

    # Nix
    nil # Nix language server
    nixfmt-rfc-style # Nix formatter
    nix-prefetch
    nix-output-monitor # Monitor Nix build outputs

    # Git
    git
    git-lfs
    git-absorb # git commit --fixup, but automatic
    gh
    act
    difftastic
    jjui
    lazygit

    # Docker
    lazydocker

    # Cloud
    awscli2
    cachix
    _1password-cli

    # Tools
    direnv # Auto-load .envrc files
    fastfetch # Display system information
    delta # Pager
    gnugrep
    ripgrep # Search tool
    ast-grep # Search tool for code
    btop
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

    bat
    broot
    eza
    duf
    du-dust
    fd # Find files
    fzf # Search files
    jq # Handle JSON
    yq # Handle YAML
    tldr

    # SSH
    mosh
    eternal-terminal

    # Encryption
    gnupg # Commit signing (no longer used, switched to SSH keys)
    blackbox # Encrypt files in git repos

    # Compression
    xz
    lzip
    p7zip
    par2cmdline

    # Chats
    irssi
    tiny

    # Misc
    cmatrix # Terminal matrix
    pastel # Color manipulation tool

    # Python
    python3

    # Haskell
    cabal-install
    stack
    ghc
    haskell-language-server
    cabal2nix

    # Rust
    cargo-outdated
    cargo-sweep
    rust-analyzer

    # Lua
    latest.lua-language-server

    # JSON
    # https://github.com/NixOS/nixpkgs/issues/335533
    latest.nodePackages.vscode-langservers-extracted

    # Image manipulation
    imagemagick

    # Docs
    pandoc

    # Videos
    yt-dlp
    streamlink
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Sander";
        email = "hey@sandydoo.me";
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me";
      };
      git.write-change-id-header = true; # Experimental feature to write the change-id to the commit header
      aliases = {
        # Move bookmark up to the current commit
        tug = [
          "bookmark"
          "move"
          "--from"
          "heads(::@- & bookmarks())"
          "--to"
          "@-"
        ];
      };
      ui = {
        default-command = "status";
        pager = "delta";
      };
      # ui.diff-formatter = [
      #   "difft"
      #   "--color=always"
      #   "$left"
      #   "$right"
      # ];
    };
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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [
      "./private/private.config"
      "./private/cachix.config"
    ]
    ++ lib.optionals isDarwin [
      "~/.orbstack/ssh/config"
    ];
    matchBlocks = lib.mkMerge [
      (lib.mkIf isDarwin {
        "nixos-vmware" = {
          hostname = "nixos-vmware";
          user = "sandydoo";
          forwardAgent = true;
          extraOptions = {
            # DEPRECATED: no longer used
            "SetEnv" = "GPG_TTY=$(tty)";
          };
        };
        "nixos-x86" = {
          hostname = "nixos-x86";
          user = "sandydoo";
          forwardAgent = true;
        };
      })
      {
        "github" = {
          hostname = "github.com";
          user = "git";
        };

        "*" = {
          addKeysToAgent = "yes";
          forwardAgent = false;
          compression = false;
          sendEnv = [
            "LANG"
            "LC_*"
            "COLORTERM"
          ];
          setEnv = {
            # Fall back to known supported terminfo entry
            "TERM" = "xterm-256color";
          };
          extraOptions = {
            # macOS only
            "IgnoreUnknown" = "UseKeychain";
            "UseKeychain" = "yes";

            "ExitOnForwardFailure" = "no";
          };
        };
      }
    ];
  };

  # Indexed search of files in nixpkgs
  programs.nix-index.enable = true;
  # Integrate nix-index-database with comma.
  # Allows directly running binaries by name without installing or setting up a shell.
  programs.nix-index-database.comma.enable = true;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  programs.direnv.config = {
    global = {
      strict_env = true;
      warn_timeout = "1h";
      hide_env_diff = true;
    };
  };

  programs.starship.enable = true;
  programs.starship.settings = {
    add_newline = true;
    command_timeout = 2000; # in milliseconds

    character = {
      success_symbol = "[➜](bold green)";
    };

    aws = {
      disabled = true;
    };
  };

  programs.bash.enable = true;
  programs.fish = {
    enable = true;
    shellAbbrs = {
      "l" = "exa -lh --git --all";
      "ls" = "exa";
      "la" = "exa -a";
      "ll" = "exa -lh";
      "lt" = "exa --tree";
      "git:undo" = "git reset HEAD~";
      "rm" = "rm -i";
      "lla" = "exa -la";
      "find" = "fd";
      "git:staged" = "git diff --staged";
      "t" = "todo.sh";
      "e" = "nvim";
    };
    shellAliases = lib.mkIf isDarwin {
      "zed-app" = "/Applications/Zed.app/Contents/MacOS/zed";
      "zed" = "/Applications/Zed.app/Contents/MacOS/cli";
      "tailscale" = "/Applications/Tailscale.app/Contents/MacOS/Tailscale";
    };
    interactiveShellInit = ''
      set fish_greeting

      # Integrate with iTerm2
      test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish

      # Added by OrbStack: command-line tools and integration
      # This won't be added again if you remove it.
      source ~/.orbstack/shell/init.fish 2>/dev/null || :
    '';
    plugins = [
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

  programs.git = {
    enable = true;
    userName = "Sander";
    userEmail = "hey@sandydoo.me";
    signing = {
      format = "ssh"; # Use SSH key for signing
      signByDefault = true;
      key = "key::ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me";
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
      gpg.ssh.allowedSignersFile = builtins.toString (
        pkgs.writeText "ssh-allowed-signers" ''
          hey@sandydoo.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me
        ''
      );
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
