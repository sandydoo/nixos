{
  config,
  pkgs,
  inputs,
  user,
  ...
}:

let
  sshAgentShellInit = ''
    if [ ! -S "''${SSH_AUTH_SOCK:-}" ] && [ -S "$HOME/.ssh/agent.sock" ]; then
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
  '';
in
{
  imports = [ ./builders ];

  users.users.${user} = {
    home = "/Users/${user}";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFQ1wc3Gq+BQ0+++gBbTmROemSby/8MNKqBCHrM7nbcS8Il4qh2We+o4Ei+jZA9LxHdCHcuBNxpAHJRn94VvyUw= asdfx"
    ];
  };

  environment.systemPackages = with pkgs; [
    home-manager
    anki-bin
  ];

  services.blackhole.enable = true;

  environment.variables = {
    EDITOR = "nvim";
    # Fix ghostty shell integration: https://github.com/ghostty-org/ghostty/discussions/2832
    XDG_DATA_DIRS = [ "$GHOSTTY_SHELL_INTEGRATION_XDG_DIR" ];
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon = {
    logFile = "/var/log/nix-daemon.log";
    tempDir = "/tmp";
  };

  nix.package = pkgs.nixVersions.latest;

  # Stable: pinned stable channel
  # nix.registry.nixpkgs.flake = nixpkgs;
  nix.registry.stable.flake = inputs.nixpkgs;
  # Latest: pinned unstable channel
  nix.registry.latest.flake = inputs.nixpkgs-unstable;
  # Nightly: unpinned unstable
  nix.registry.nightly.to = {
    owner = "NixOS";
    ref = "nixpkgs-unstable";
    repo = "nixpkgs";
    type = "github";
  };
  # Only for legacy channel stuff, i.e. <nixpkgs>
  nix.nixPath = [
    "nixpkgs=${config.nix.registry.stable.flake}"
    "stable=${config.nix.registry.stable.flake}"
    "latest=${config.nix.registry.latest.flake}"
  ];

  # Periodically run the store optimizer.
  # auto-optimise-store is known to corrupt the store.
  nix.optimise.automatic = true;

  # Enable garbage collection.
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 1;
      Hour = 0;
      Minute = 0;
    };
    options = "--delete-older-than 30d";
  };

  nix.extraOptions = ''
    darwin-log-sandbox-violations = true # Log sandbox violations to /var/log/nix/sandbox.log
    experimental-features = nix-command flakes configurable-impure-env
    http-connections = 75 # This also controls the thread pool size when querying caches
    keep-derivations = false
    keep-outputs = false
    log-lines = 50 # Number of lines to show when builds fail
    warn-dirty = false # Don't warn about dirty git trees
    # Pass custom certs to the daemon
    # ssl-cert-file = /etc/nix/macos-keychain.crt
  '';

  # Test MITM SSL certificate setups, like ZScaler, with mitmproxy.
  # security.pki.certificateFiles = [ "/etc/ssl/mitmproxy-ca-cert.pem" ];
  # security.pki.installCACerts = true;

  # Try enabling sandboxing on macOS.
  # nix.settings.sandbox = "relaxed";
  nix.settings.sandbox = false;

  nix.settings.connect-timeout = 1;

  nix.settings.trusted-users = [ "${user}" ];
  nix.settings.substituters = [
    "https://nix-community.cachix.org?priority=41"
  ];
  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  # Remote shells do not inherit the GUI login's SSH agent socket.
  environment.extraInit = sshAgentShellInit;
  programs.bash.interactiveShellInit = sshAgentShellInit;
  programs.zsh.enable = true;
  programs.zsh.shellInit = sshAgentShellInit;
  programs.fish.enable = true;
  programs.fish.shellInit = ''
    if not test -S "$SSH_AUTH_SOCK"; and test -S "$HOME/.ssh/agent.sock"
      set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
    end
  '';
  # Work around incorrect order in PATH. These paths need to come before
  # the system ones.
  # https://github.com/LnL7/nix-darwin/issues/122
  programs.fish.loginShellInit = ''
    fish_add_path --move --prepend --path /run/current-system/sw/bin /nix/var/nix/profiles/default/bin

    # Add UTM and utmctl commands
    fish_add_path /Applications/UTM.app/Contents/MacOS/

    set -x PINENTRY_USER_DATA "USE_MAC=1"
  '';

  # Support projects that use lorri
  services.lorri.enable = true;

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  launchd.user.agents = {
    "ssh-add" = {
      script = ''
        # Publish a stable path to the existing macOS agent at each GUI login.
        if [ -S "''${SSH_AUTH_SOCK:-}" ]; then
          /bin/mkdir -p "$HOME/.ssh"
          /bin/ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
        fi
        /usr/bin/ssh-add --apple-load-keychain --apple-use-keychain
      '';
      serviceConfig.RunAtLoad = true;
    };
    "xdr-boost" = {
      serviceConfig = {
        ProgramArguments = [ "${pkgs.xdr-boost}/bin/xdr-boost" ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };

  # Required by launchd.user.agents.
  system.primaryUser = user;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;
}
