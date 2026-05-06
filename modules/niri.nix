{ config, pkgs, lib, inputs, user, ... }:

{
  programs.niri.enable = true;
  programs.xwayland.enable = true;

  security.polkit.enable = true;
  programs.dconf.enable = true;

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

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
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
