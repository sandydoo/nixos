{ config, pkgs, lib, inputs, user, ... }:

{
  imports = [ inputs.niri.nixosModules.niri ];

  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-unstable;

  services.greetd = {
    enable = true;
    settings = {
      default_session.command =
        "${lib.getExe pkgs.tuigreet} --time --cmd niri-session";
      initial_session = {
        command = "niri-session";
        user = user;
      };
    };
  };
}
