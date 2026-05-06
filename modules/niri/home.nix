{ config, ... }:

{
  programs.niri.settings = {
    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn "ghostty";
      "Mod+T".action = spawn "ghostty";
    };
  };
}
