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
  systemd.targets.getty.wants = [ "getty@tty2.service" ];

  # An instance-specific getty drop-in would shadow NixOS's template drop-in,
  # losing its store paths for agetty and login. Switch VTs in a separate unit.
  systemd.services.console-tty2 = {
    description = "Switch to the tty2 console";
    wantedBy = [ "multi-user.target" ];
    requires = [ "getty@tty2.service" ];
    after = [ "getty@tty2.service" ];
    restartIfChanged = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' pkgs.kbd "chvt"} 2";
    };
  };

  # Return to the console when the desktop is stopped.
  systemd.services.display-manager.postStop = "${lib.getExe' pkgs.kbd "chvt"} 2";

  nixpkgs.config.allowUnsupportedSystem = true;
}
