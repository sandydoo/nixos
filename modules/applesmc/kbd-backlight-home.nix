{ config, pkgs, ... }:

{
  programs.niri.settings.binds = with config.lib.niri.actions; {
    "XF86KbdBrightnessUp" = {
      action = spawn "brightnessctl" "--device=smc::kbd_backlight" "set" "+10%";
      allow-when-locked = true;
    };
    "XF86KbdBrightnessDown" = {
      action = spawn "brightnessctl" "--device=smc::kbd_backlight" "set" "10%-";
      allow-when-locked = true;
    };
  };
}
