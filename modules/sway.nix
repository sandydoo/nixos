{ pkgs, lib, ... }:

{
  programs.sway.enable = true;
  programs.xwayland.enable = true;

  security.polkit.enable = true;

  services.greetd = {
    enable = true;
    settings = {
      default_session.command = "${lib.getExe pkgs.greetd.tuigreet} --time --cmd sway";
      initial_session = {
        command = "sway";
        user = "sandydoo";
      };
    };
  };

  environment.systemPackages = [ pkgs.wdisplays ];
}
