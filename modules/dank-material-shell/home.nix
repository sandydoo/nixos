{ inputs, ... }:

{
  imports = [
    inputs.dank-material-shell.homeModules.dank-material-shell
    inputs.dank-material-shell.homeModules.niri
  ];

  programs.dank-material-shell.enable = true;
  programs.dank-material-shell.systemd.enable = true;
  programs.dank-material-shell.niri.enableKeybinds = true;
  programs.dank-material-shell.niri.includes.enable = false;
}
