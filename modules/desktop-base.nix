{ pkgs, ... }:

{
  services.accounts-daemon.enable = true;
  services.power-profiles-daemon.enable = true;
  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  fonts.packages = with pkgs; [
    inter
    material-symbols
    nerd-fonts.jetbrains-mono
  ];

  environment.systemPackages = with pkgs; [
    cups-pk-helper
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
