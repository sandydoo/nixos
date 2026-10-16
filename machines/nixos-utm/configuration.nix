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
