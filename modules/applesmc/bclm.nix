{ config, lib, pkgs, ... }:

let
  cfg = config.services.applesmc-bclm;
in
{
  options.services.applesmc-bclm = {
    enable = lib.mkEnableOption "Apple SMC battery charge limit (BCLM key)";

    limit = lib.mkOption {
      type = lib.types.ints.between 20 100;
      default = 80;
      description = ''
        Maximum charge percentage (BCLM value).
        Persists in SMC NVRAM across reboots until SMC reset.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.applesmc-bclm = {
      description = "Apple SMC battery charge limit (BCLM=${toString cfg.limit})";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];

      path = [ pkgs.kmod pkgs.bclm ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        rmmod applesmc 2>/dev/null || true
        bclm set ${toString cfg.limit}
        modprobe applesmc
      '';
    };
  };
}
