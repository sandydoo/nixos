{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [ inputs.niri.nixosModules.niri ];

  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session.command =
        "${lib.getExe pkgs.greetd.tuigreet} --time --cmd niri-session";
      initial_session = {
        command = "niri-session";
        user = user;
      };
    };
  };

  fonts.packages = with pkgs; [
    inter
    material-symbols
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    wl-clipboard
    waypipe
    wdisplays
    brightnessctl
    playerctl
    grim
    slurp
    swappy
    wf-recorder
    libnotify
  ];
}
