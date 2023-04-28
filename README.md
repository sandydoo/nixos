# NixOS Configs

## Nix Darwin machines

There's a 2-step process to building a Nix Darwin machine from a flake:

```bash
nix build ./#darwinConfigurations.asdfPro.system
```

```bash
./result/sw/bin/darwin-rebuild switch --flake ./
```

## Maintenance

### Delete older generations

Eventually, the boot drive will fill up with older generations. This is particularly a problem when using a custom kernel version.
To delete the older generations, run the following:

```bash
nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
/run/current-system/bin/switch-to-configuration switch
```
