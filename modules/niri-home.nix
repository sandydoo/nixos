{ inputs, ... }:

{
  imports = [
    inputs.dank-material-shell.homeModules.dank-material-shell
    inputs.dank-material-shell.homeModules.niri
  ];

  programs.niri.settings = { };

  programs.dank-material-shell.enable = true;
  programs.dank-material-shell.niri.enableKeybinds = false;
  programs.dank-material-shell.niri.includes.enable = true;
}
