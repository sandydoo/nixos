# Remote builders for asdfpro.
#
# The Mac cannot run Linux builds itself.
# Linux derivations go to the machines below through the build hook.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  utmBuilder = {
    hostName = "nixos-utm";
    sshUser = "remotebuilder";
    sshKey = "/etc/nix/builder_ed25519";
    publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSVBDYzdTRzJqY2cyUHRuWlppRys4bHRIazY2OURMTmZOQUQ2ZWd3YVI3Ty8=";
    protocol = "ssh-ng";
    speedFactor = 1;
  };

  builderDown = pkgs.writeShellApplication {
    name = "nix-builder-down";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./builder-down.sh;
  };

  sshBuilders = lib.unique (
    map
      (builder: {
        inherit (builder) hostName sshUser;
      })
      (builtins.filter (
        builder: builtins.elem builder.protocol [ "ssh" "ssh-ng" ]
      ) config.nix.buildMachines)
  );
in
{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  nix.buildMachines = [
    (utmBuilder // {
      maxJobs = 4;
      supportedFeatures = [
        "kvm"
        "benchmark"
        "big-parallel"
        "nixos-test"
      ];
      systems = [ "aarch64-linux" ];
    })
    (utmBuilder // {
      maxJobs = 2;
      supportedFeatures = [ "big-parallel" ];
      systems = [ "x86_64-linux" ];
    })
    {
      hostName = "nixos-x86";
      sshUser = "remotebuilder";
      sshKey = "/etc/nix/builder_ed25519";
      # ssh-keyscan -t ed25519 <HOSTNAME> | grep "ssh-ed25519" | cut -d' ' -f2,3 | tr -d '\n' | base64 -w0
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUxibjJJV0J6cFNJazhoSmZIKy9LdXprdVVrekFxYVRoZ2F3SWx1MHFGTlU=";
      maxJobs = 4;
      protocol = "ssh-ng";
      speedFactor = 2;
      supportedFeatures = [
        "kvm"
        "benchmark"
        "big-parallel"
        "nixos-test"
      ];
      systems = [ "x86_64-linux" ];
    }
  ];

  # Do not let unreachable remote builders stall builds.
  # build-remote disables a builder for the rest of a build session after
  # its first failed connection.
  # The probe makes that first failure instant and remembers it across
  # sessions (see builder-down.sh).
  # This is read by the nix-daemon's ssh via /etc/ssh/ssh_config.
  programs.ssh.extraConfig = lib.concatMapStringsSep "\n" (
    builder:
    let
      match = "host ${builder.hostName}" + lib.optionalString (builder.sshUser != null) " user ${builder.sshUser}";
    in
    ''
      Match ${match} exec "${builderDown}/bin/nix-builder-down %h"
        ProxyCommand /usr/bin/false
      Match ${match}
        ConnectTimeout 5
    ''
  ) sshBuilders;

  nix.linux-builder = {
    enable = false;
    maxJobs = 4;
    supportedFeatures = [
      "kvm"
      "benchmark"
      "big-parallel"
      "nixos-test"
    ];
    config =
      { lib, ... }:
      {
        # A small set of builder options are available
        # virtualisation.darwin-builder.memorySize = 8 * 1024;

        virtualisation.cores = 4;
        virtualisation.memorySize = lib.mkForce (8 * 1024);
      };
  };
}
