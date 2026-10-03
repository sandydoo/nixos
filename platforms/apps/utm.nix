# UTM: settings that UTM chooses, not the hypervisor.
#
# Install with `nix run .#utm-install` (pkgs/utm-install).
{ config, lib, ... }:

{
  config = lib.mkIf (config.machine.app == "utm") {
    # "Enable Rosetta" in UTM shares Rosetta with this virtiofs tag.
    virtualisation.rosetta.mountTag = "rosetta";
  };
}
