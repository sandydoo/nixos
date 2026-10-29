{ pkgs, user, ... }:

{
  services.xserver.enable = true;

  services.displayManager = {
    gdm = {
      enable = true;
      autoSuspend = false;
    };
    defaultSession = "gnome";
    autoLogin = {
      enable = true;
      user = "sandydoo";
    };
  };

  services.desktopManager.gnome.enable = true;

  # Reserve tty1 for GDM's automatic login.
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.systemPackages = [
    pkgs.gnome-tweaks
    pkgs.wl-clipboard
    pkgs.waypipe
  ];

  programs.dconf.enable = true;
  home-manager.users.${user} =
    { lib, ... }:
    {
      dconf.settings."org/gnome/desktop/session".idle-delay = lib.hm.gvariant.mkUint32 0;
    };
  programs.xwayland.enable = true;
}
