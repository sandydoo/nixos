{ nix-unstable, ...}:

{
  virtualisation.vmware.guest = {
    enable = true;
    headless = false;
  };

  boot.loader.grub = {
    enable = true;
    version = 2;
    device = "/dev/sda";
  };
}
