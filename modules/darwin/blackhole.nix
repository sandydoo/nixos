{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.blackhole;
  driverName = "Blackhole${cfg.channel}.driver";
  halDir = "/Library/Audio/Plug-Ins/HAL";
  stateFile = "${halDir}/.nix-darwin-blackhole";
in
{
  options.services.blackhole = {
    enable = lib.mkEnableOption "BlackHole virtual audio driver";

    channel = lib.mkOption {
      type = lib.types.str;
      default = "2ch";
      description = "Channel variant of the BlackHole driver.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.blackhole.override { channel = cfg.channel; };
      defaultText = lib.literalExpression "pkgs.blackhole.override { channel = config.services.blackhole.channel; }";
      description = "The BlackHole driver package to install.";
    };
  };

  config.system.activationScripts.preActivation.text = lib.mkMerge [
    (lib.mkIf cfg.enable ''
      _bh_expected="${driverName} ${cfg.package}"
      if [ -f "${stateFile}" ] && [ "$(cat "${stateFile}")" = "$_bh_expected" ]; then
        : # BlackHole driver already installed and up to date
      else
        echo "installing BlackHole ${cfg.channel} audio driver..." >&2
        mkdir -p ${halDir}
        chown root:wheel ${halDir}

        # Remove previously installed driver if channel changed
        if [ -f "${stateFile}" ]; then
          _bh_old=$(cut -d' ' -f1 "${stateFile}")
          if [ "$_bh_old" != "${driverName}" ]; then
            echo "removing old BlackHole driver $_bh_old..." >&2
            rm -rf "${halDir}/$_bh_old"
          fi
        fi

        rm -rf "${halDir}/${driverName}"
        cp -pR "${cfg.package}${halDir}/${driverName}" "${halDir}/${driverName}"
        chown -R root:wheel "${halDir}/${driverName}"

        echo "$_bh_expected" > "${stateFile}"
        killall -9 coreaudiod 2>/dev/null || true
      fi
    '')
    (lib.mkIf (!cfg.enable) ''
      if [ -f "${stateFile}" ]; then
        _bh_old=$(cut -d' ' -f1 "${stateFile}")
        echo "removing BlackHole driver $_bh_old..." >&2
        rm -rf "${halDir}/$_bh_old"
        rm -f "${stateFile}"
        killall -9 coreaudiod 2>/dev/null || true
      fi
    '')
  ];
}
