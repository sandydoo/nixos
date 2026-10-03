# Disks of this machine. The Hyper-V parts are in platforms/hyperv.
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/3827d0ea-4d6f-490b-807b-41b71944ae8b";
    fsType = "btrfs";
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/3827d0ea-4d6f-490b-807b-41b71944ae8b";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/3827d0ea-4d6f-490b-807b-41b71944ae8b";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6327-AFF4";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  swapDevices = [ ];
}
