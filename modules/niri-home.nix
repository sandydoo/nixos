{ inputs, config, ... }:

{
  imports = [
    inputs.dank-material-shell.homeModules.dank-material-shell
    inputs.dank-material-shell.homeModules.niri
  ];

  programs.niri.settings = {
    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn "ghostty";
      "Mod+T".action = spawn "ghostty";
    };
  };

  programs.dank-material-shell.enable = true;
  programs.dank-material-shell.systemd.enable = true;
  programs.dank-material-shell.niri.enableKeybinds = false;
  programs.dank-material-shell.niri.includes.enable = true;
}
