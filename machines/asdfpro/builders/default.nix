# Remote builders for asdfpro.
#
# The Mac cannot run Linux builds itself.
# Linux derivations go to the machines below through the build hook.
{ pkgs, ... }:

let
  builderDown = pkgs.writeShellApplication {
    name = "nix-builder-down";
    runtimeInputs = [ pkgs.coreutils ];
    text = builtins.readFile ./builder-down.sh;
  };
in
{
  nix.distributedBuilds = true;
  nix.settings.builders-use-substitutes = true;

  nix.buildMachines = [
    {
      hostName = "nixos-vmware";
      sshUser = "remotebuilder";
      sshKey = "/etc/nix/builder_ed25519";
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUQ3V1pUYjliUjRJUG9kbnhESXZDVkxwZjg3UWpSdFNZQ1pYc1kvdVBVdTM=";
      maxJobs = 4;
      protocol = "ssh-ng";
      speedFactor = 1;
      # No kmv/nixos-test here because vmware doesn't support nested virt.
      supportedFeatures = [
        "benchmark"
        "big-parallel"
      ];
      systems = [ "aarch64-linux" ];
    }
    {
      hostName = "nixos-vmware";
      sshUser = "remotebuilder";
      sshKey = "/etc/nix/builder_ed25519";
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUQ3V1pUYjliUjRJUG9kbnhESXZDVkxwZjg3UWpSdFNZQ1pYc1kvdVBVdTM=";
      maxJobs = 2;
      protocol = "ssh-ng";
      speedFactor = 1;
      supportedFeatures = [ "big-parallel" ];
      systems = [ "x86_64-linux" ];
    }
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

  # Do not let an unreachable nixos-vmware stall builds.
  # build-remote disables a builder for the rest of a build session after
  # its first failed connection.
  # The probe makes that first failure instant and remembers it across
  # sessions (see builder-down.sh).
  # This is read by the nix-daemon's ssh via /etc/ssh/ssh_config.
  programs.ssh.extraConfig = ''
    Match host nixos-vmware user remotebuilder exec "${builderDown}/bin/nix-builder-down %h"
      ProxyCommand /usr/bin/false
    Match host nixos-vmware user remotebuilder
      ConnectTimeout 5
  '';

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
