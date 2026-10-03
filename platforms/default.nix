# How a NixOS machine runs: on which hypervisor, and with which app.
#
# A VM is described by:
# - the guest platform: `system` in machines/default.nix,
# - the hypervisor: `machine.platform`,
# - the virtualization app: `machine.app` (optional),
# - the host platform: `machine.host`, derived from the others.
#
# Set `machine.platform` and `machine.app` in machines/<machine>/configuration.nix.
# Each platform and app module applies only to its own platform or app.
{ config, lib, ... }:

let
  cfg = config.machine;
  guest = config.nixpkgs.hostPlatform;

  # Hypervisors, with the host OS they need (null if more than one).
  hypervisors = {
    hyperv = "windows";
    vmware = null; # Fusion on macOS, Workstation on Windows and Linux
    apple-vz = "darwin";
  };

  # Virtualization apps, with the hypervisors they can use and their host OS.
  apps = {
    utm = {
      platforms = [ "apple-vz" ];
      hostOs = "darwin";
    };
    vmware-fusion = {
      platforms = [ "vmware" ];
      hostOs = "darwin";
    };
  };

  hostOs =
    if cfg.app != null then
      apps.${cfg.app}.hostOs
    else if cfg.platform != null then
      hypervisors.${cfg.platform}
    else
      null;
in
{
  imports = [
    ./hyperv.nix
    ./vmware.nix
    ./apple-vz
    ./apps/utm.nix
  ];

  options.machine = {
    platform = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames hypervisors));
      default = null;
      description = "The hypervisor that runs this machine, or null for none.";
    };

    app = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum (lib.attrNames apps));
      default = null;
      description = "The virtualization app that runs this machine, or null for no app-specific settings.";
    };

    host = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      readOnly = true;
      # The hypervisors use hardware virtualization, not emulation.
      # So the host has the same CPU architecture as the guest.
      default =
        if hostOs == null then null else lib.systems.elaborate "${guest.parsed.cpu.name}-${hostOs}";
      defaultText = lib.literalMD "derived from `machine.app`, `machine.platform` and `nixpkgs.hostPlatform`";
      description = ''
        The platform of the host computer, as an elaborated system
        (for example `aarch64-darwin` for an Apple silicon Mac).
        Null if neither the app nor the hypervisor fixes the host OS.
      '';
    };
  };

  config.assertions = lib.optional (cfg.app != null) {
    assertion = lib.elem cfg.platform apps.${cfg.app}.platforms;
    message = "machine.app = \"${cfg.app}\" cannot use machine.platform = ${
      if cfg.platform == null then "null" else "\"${cfg.platform}\""
    }. It supports: ${lib.concatStringsSep ", " apps.${cfg.app}.platforms}.";
  };
}
