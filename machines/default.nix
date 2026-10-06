# All machines of this flake.
#
# Each NixOS machine has its configuration in machines/<machine>/.
# The hypervisor of a VM is set there with `machine.platform` (see platforms/).
{ inputs, mkSystem }:

let
  inherit (inputs.nixpkgs) lib;
in
{
  nixosConfigurations =
    lib.mapAttrs mkSystem {
      # Development VMs: modules/dev-vm.nix on different hypervisors.
      nixos-x86 = {
        system = "x86_64-linux";
        user = "sandydoo";
        modules = [
          ../modules/gnome.nix
          ../modules/tailscale.nix
        ];
      };

      nixos-vmware = {
        system = "aarch64-linux";
        user = "sandydoo";
        modules = [
          ../modules/gnome.nix
          ../modules/tailscale.nix
        ];
      };

      nixos-utm = {
        system = "aarch64-linux";
        user = "sandydoo";
        modules = [
          ../modules/gnome.nix
          ../modules/tailscale.nix
        ];
      };

      nixos = {
        system = "aarch64-linux";
        user = "sandydoo";
        modules = [
          ../modules/sway.nix
          ../modules/tailscale.nix
        ];
      };

      nixos-mbp = {
        system = "x86_64-linux";
        user = "sandydoo";
        modules = [
          ../modules/desktop-base.nix
          ../modules/niri
          ../modules/tailscale.nix
        ];
        homeModules = [
          ../modules/niri/home.nix
          ../modules/dank-material-shell/home.nix
          ../modules/applesmc/kbd-backlight-home.nix
          ../modules/no-gpg-home.nix
        ];
      };

    }
    // {
      # Installer ISO used by `nix run .#utm-install`.
      nixos-utm-installer = inputs.nixpkgs.lib.nixosSystem {
        modules = [ ../platforms/apple-vz/installer.nix ];
      };
    };

  darwinConfigurations = lib.mapAttrs mkSystem {
    asdfpro = {
      system = "aarch64-darwin";
      user = "sander";
      nixUser = "sandydoo";
      modules = [
        ../modules/darwin/blackhole.nix
      ];
    };

    asdfpro5 = {
      machine = "asdfpro";
      system = "aarch64-darwin";
      user = "sandydoo";
      modules = [
        ../modules/darwin/blackhole.nix
      ];
    };
  };
}
