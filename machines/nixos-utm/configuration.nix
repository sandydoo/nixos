{ pkgs, user, ... }:

let
  displayProfile = pkgs.writeText "utm-kanshi.conf" ''
    profile {
      output * scale 1
    }
  '';
in
{
  imports = [
    ../../modules/dev-vm.nix
    ../../modules/datadog-agent.nix
  ];

  machine.platform = "apple-vz";
  machine.app = "utm";

  # Trap guest GIC register accesses to prevent nested KVM CPU lockups.
  # See README.md: "Nested KVM on nixos-utm".
  boot.kernelParams = [
    "kvm-arm.vgic_v3_group1_trap=1"
    "kvm-arm.vgic_v3_common_trap=1"
  ];

  networking.hostName = "nixos-utm";
  environment.systemPackages = [ pkgs.dix ];

  services.spice-vdagentd.enable = true;
  services.cage = {
    enable = true;
    inherit user;
    program = pkgs.writeShellScript "utm-terminal" ''
      ${pkgs.kanshi}/bin/kanshi -c ${displayProfile} &
      spice-vdagent

      while true; do
        # Scale inside Ghostty so Cage displays the Xwayland surface pixel-for-pixel.
        GDK_BACKEND=x11 GDK_SCALE=2 ghostty --working-directory="$HOME" \
          --gtk-single-instance=false --quit-after-last-window-closed=true
        sleep 1
      done
    '';
  };
  systemd.services.cage-tty1 = {
    path = [ pkgs.spice-vdagent pkgs.ghostty ];
    serviceConfig.Restart = "always";
  };

  home-manager.users.${user}.programs.fish.interactiveShellInit = ''
    if test "$TERM_PROGRAM" = ghostty
      bind ctrl-d delete-char
    end
  '';

  nixpkgs.config.allowUnsupportedSystem = true;
}
