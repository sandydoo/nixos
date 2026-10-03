{ inputs, ... }:

{
  imports = [
    "${inputs.self}/modules/dev-vm.nix"
    "${inputs.self}/modules/datadog-agent.nix"
  ];

  machine.platform = "apple-vz";
  machine.app = "utm";

  networking.hostName = "nixos-utm";

  nixpkgs.config.allowUnsupportedSystem = true;
}
