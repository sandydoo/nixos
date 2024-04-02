# NixOS Configs

## Nix Darwin machines

There's a 2-step process to building a Nix Darwin machine from a flake:

```bash
nix build ./#darwinConfigurations.asdfPro.system
```

```bash
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


## Maintenance

### Delete older generations

Eventually, the boot drive will fill up with older generations. This is particularly a problem when using a custom kernel version.
To delete the older generations, run the following:

```console
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
sudo /run/current-system/bin/switch-to-configuration switch
```

### Delete Home Manager generations

These are not currently automatically removed.
See https://github.com/nix-community/home-manager/issues/3450.

```console
home-manager expire-generations "-180 days"
```

### Run GC

```console
sudo nix-collect-garbage --delete-older-than 180d
```
