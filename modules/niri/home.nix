{ config, ... }:

{
  programs.niri.settings = {
    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn "ghostty" "+new-window";
      "Mod+T".action = spawn "ghostty" "+new-window";
    };
  };
}
