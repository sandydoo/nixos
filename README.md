# NixOS Configs

## NixOS machines

```shell
nixos-rebuild switch --sudo
```

## Nix Darwin machines

There's a 2-step process to building a Nix Darwin machine from a flake:

```shell
nix build ./#darwinConfigurations.asdfpro.system
```

```shell
./result/sw/bin/darwin-rebuild switch --flake ./
```

## Setting up VMs on a macOS host

#### How do I change the default NAT subnet for VMs?

```shell
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.vmnet.plist Shared_Net_Address -string 192.168.64.1
```

Restart the DHCP server:

```shell
sudo /bin/launchctl kickstart -kp system/com.apple.bootpd
```

#### How do I give a VM a static IP address?

Note the MAC address of the VM's network interface. Then, add an entry to `/etc/bootptab`:

```
%%
# hostname      hwtype  hwaddr              ipaddr          bootfile
nixos           1       0A:1E:0E:51:29:4C   192.168.64.2
```

Restart the DHCP server:

```shell
sudo /bin/launchctl kickstart -kp system/com.apple.bootpd
```

#### I'm running out of IP addresses. How do I increase the number of VMs I can run?

Reduce the lease time for DHCP leases. The default is 86400 seconds (24 hours). The following command will reduce it to 600 seconds (10 minutes):

```
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.InternetSharing.default.plist bootpd -dict DHCPLeaseTimeSecs -int 600
```

### Nested KVM on nixos-utm

Linux 6.19+ can hang nested ARM guests under Apple Virtualization because of a regression in GIC interrupt handling.
Apply these kernel parameters to the outer Linux VM, as set in the [machine configuration](machines/nixos-utm/configuration.nix):

```nix
boot.kernelParams = [
  "kvm-arm.vgic_v3_group1_trap=1"
  "kvm-arm.vgic_v3_common_trap=1"
];
```

[Regression report](https://github.com/agent-substrate/substrate/pull/3149) · [Kernel commit](https://github.com/torvalds/linux/commit/73c9726975af1c2bf8d062017c67bcf4fb8821d5)

#### Guest memory

Nested KVM on Apple Virtualization is slow with 4 KiB guest RAM pages because nested page-table faults are expensive.
Use 2 MiB backing pages by adding these properties to each QEMU `memory-backend-memfd` object:

```text
hugetlb=on,hugetlbsize=2097152
```

Reserve enough hugetlb pages for all guest RAM before starting QEMU.
[Implementation notes](https://github.com/AlexanderMattTurner/agent-glovebox/blob/675906914f190d437f67bb491e56eb68ef274d24/bin/lib/kata_layout.py#L112-L125)

## Maintenance

### Delete older generations

Eventually, the boot drive will fill up with older generations. This is particularly a problem when using a custom kernel version.
To delete the older generations, run the following:

```shell
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
sudo /run/current-system/bin/switch-to-configuration switch
```

### Delete Home Manager generations

These are not currently automatically removed.
See <https://github.com/nix-community/home-manager/issues/3450>.

```shell
home-manager expire-generations "-180 days"
```

### Run GC

```shell
sudo nix-collect-garbage --delete-older-than 180d
```
