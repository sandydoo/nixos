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

  # Boot to a console; start GNOME with `sudo systemctl start display-manager`.
  systemd.defaultUnit = lib.mkForce "multi-user.target";
  services.getty.autologinUser = "sandydoo";

  # Keep a console on tty2, separate from GDM on tty1.
  systemd.services."getty@tty2" = {
    overrideStrategy = "asDropin";
    wantedBy = [ "getty.target" ];
    restartIfChanged = false;
    serviceConfig.ExecStartPre = "${lib.getExe' pkgs.kbd "chvt"} 2";
  };

  # Return to the console when the desktop is stopped.
  systemd.services.display-manager.postStop = "${lib.getExe' pkgs.kbd "chvt"} 2";

  nixpkgs.config.allowUnsupportedSystem = true;
}
