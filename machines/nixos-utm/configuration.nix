{
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    "${inputs.self}/modules/dev-vm.nix"
    "${inputs.self}/modules/datadog-agent.nix"
  ];

  machine.platform = "apple-vz";
  machine.app = "utm";

  # Trap guest GIC register accesses to prevent nested KVM CPU lockups.
  # See README.md: "Nested KVM on nixos-utm".
  boot.kernelParams = [
    "kvm-arm.vgic_v3_group1_trap=1"
    "kvm-arm.vgic_v3_common_trap=1"
  ];

  networking.hostName = "nixos-utm";

  systemd.defaultUnit = "multi-user.target";
  services.getty.autologinUser = "sandydoo";

    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
    };
  };


  nixpkgs.config.allowUnsupportedSystem = true;
}
