# Create a UTM VM (Apple Virtualization backend) and install a NixOS
# configuration from a flake onto it with nixos-anywhere.
#
# Steps:
#   1. Build the installer ISO (nixosConfigurations.nixos-utm-installer).
#   2. Create the VM with AppleScript and enable Rosetta in config.plist.
#   3. Boot the ISO and find the VM IP.
#   4. Partition with disko and install with nixos-anywhere.
#      The system is built on the VM itself.
#   5. Remove the ISO and boot the installed system.

const SSH_OPTS = [
  -o BatchMode=yes
  -o ConnectTimeout=5
  -o StrictHostKeyChecking=no
  -o UserKnownHostsFile=/dev/null
  -o LogLevel=ERROR
]

def step [message: string] {
  print --stderr $"\n==> ($message)"
}

# Arguments go to the AppleScript's `on run argv` handler.
def applescript [script: string, ...args: string] {
  $script | ^/usr/bin/osascript - ...$args | str trim
}

def vm-status [vm_id: string] {
  applescript '
on run argv
  tell application "UTM" to return (status of virtual machine id (item 1 of argv)) as text
end run
' $vm_id
}

def wait-for-status [vm_id: string, want: string] {
  for _ in 1..120 {
    if (vm-status $vm_id) == $want { return }
    sleep 1sec
  }
  error make {msg: $"VM did not reach status '($want)'"}
}

def start-vm [vm_id: string] {
  applescript '
on run argv
  tell application "UTM"
    set vm to virtual machine id (item 1 of argv)
    reload configuration of vm
    start vm
  end tell
end run
' $vm_id | ignore
}

# Set a key in config.plist, or add it when it does not exist.
def plist-set [config: path, key: string, type: string, value: string] {
  let result = (^/usr/libexec/PlistBuddy -c $"Set :($key) ($value)" $config | complete)
  if $result.exit_code != 0 {
    ^/usr/libexec/PlistBuddy -c $"Add :($key) ($type) ($value)" $config
  }
}

def lease-ip [mac: string, leases: path] {
  # The vmnet DHCP server drops leading zeros in each MAC octet.
  let short_mac = ($mac | split row ':' | each { str replace --regex '^0' '' } | str join ':')
  let contents = (try { open --raw $leases } catch { '' })
  mut found = ''
  for lease in ($contents | parse --regex '(?s)\{(?P<lease>.*?)\}' | get lease) {
    let fields = ($lease | lines | str trim | parse '{key}={value}'
      | transpose --ignore-titles --header-row --as-record)
    if $fields.hw_address? == $"1,($short_mac)" {
      $found = ($fields.ip_address? | default '')
    }
  }
  $found
}

def wait-for-ip [mac: string, leases: path] {
  for _ in 1..180 {
    let ip = (lease-ip $mac $leases)
    if $ip != '' { return $ip }
    sleep 1sec
  }
  error make {msg: $"no DHCP lease for ($mac) in ($leases)"}
}

def wait-for-ssh [target: string] {
  for _ in 1..180 {
    let result = (^ssh ...$SSH_OPTS $target true | complete)
    if $result.exit_code == 0 { return }
    sleep 2sec
  }
  error make {msg: $"cannot connect to ($target) with SSH"}
}

def guest-ip [vm_id: string, mac: string] {
  for _ in 1..30 {
    let ip = (try { applescript '
on run argv
  tell application "UTM" to set addresses to query ip (virtual machine id (item 1 of argv))
  repeat with addr in addresses
    if (addr as text) contains "." then return addr as text
  end repeat
  return ""
end run
' $vm_id } catch { '' })
    if $ip != '' { return $ip }
    sleep 1sec
  }
  # Apple Virtualization looks up the MAC in the host ARP cache, which may be empty.
  input $"Enter the guest IPv4 address leased to ($mac): " | str trim
}

# Create a UTM VM and install NixOS onto it with nixos-anywhere.
def main [
  --name: string = 'nixos-utm' # UTM VM name
  --flake: string = '.' # Flake that has the configuration
  --attr: string = 'nixos-utm' # nixosConfigurations attribute to install
  --cpus: int = 8 # CPU cores
  --memory: int = 16384 # Memory in MiB
  --disk-size: int = 128 # Disk size in GiB
  --network: string = 'shared' # Installed VM network: shared, nat (macOS 26+), none, or bridge
  --interface: string # Bridge interface: auto (default) or a macOS device such as en0
  --iso: path # Use this installer ISO instead of building one
  --extra-files: path # Copy the contents of this directory to / on the new system
] {
  if $network not-in [shared nat none bridge] {
    error make {msg: '--network must be shared, nat, none, or bridge'}
  }
  if $interface != null and $network != 'bridge' {
    error make {msg: '--interface requires --network bridge'}
  }
  let bridge_interface = ($interface | default 'auto')
  if $network == 'nat' and ((^sw_vers -productVersion | split row '.' | first | into int) < 26) {
    error make {msg: 'UTM NAT Network requires macOS 26 or newer'}
  }
  # nixos-anywhere needs SSH until the installed VM is ready for its first boot.
  let install_network = if $network == 'none' { 'shared' } else { $network }
  for option in ({cpus: $cpus, memory: $memory, disk-size: $disk_size} | transpose key value) {
    if $option.value <= 0 {
      error make {msg: $"--($option.key) must be positive"}
    }
  }

  let bundle = ($nu.home-dir | path join 'Library/Containers/com.utmapp.UTM/Data/Documents' $"($name).utm")
  let config = ($bundle | path join 'config.plist')
  let leases = '/var/db/dhcpd_leases'

  if ($bundle | path exists) {
    error make {msg: $"($bundle) exists. Delete the VM in UTM or use --name."}
  }

  let installer_iso = if $iso == null {
    step 'Building the installer ISO'
    let iso_dir = (^nix build --no-link --print-out-paths
      $"($flake)#nixosConfigurations.nixos-utm-installer.config.system.build.isoImage" | str trim)
    glob ($iso_dir | path join 'iso' '*.iso') | sort | first
  } else {
    $iso | path expand
  }
  if ($installer_iso | path type) != 'file' {
    error make {msg: $"ISO not found: ($installer_iso)"}
  }

  # A random, locally administered MAC address identifies the VM in DHCP leases.
  let octets = (1..5 | each {
    random int 0..255 | format number --no-prefix | get lowerhex
      | fill --alignment right --character '0' --width 2
  })
  let mac = (['02'] | append $octets | str join ':')

  step $"Creating VM '($name)' \(MAC ($mac)\)"
  # POSIX file must be resolved outside the `tell` block.
  let vm_id = (applescript '
on run argv
  set {vmName, isoPath, mem, cpus, diskMiB, mac, bridgeName, networkMode} to argv
  set iso to POSIX file isoPath
  tell application "UTM"
    set nic to {mode:shared, address:mac}
    if networkMode is "nat" then
      set nic to {mode:nat network, address:mac}
    else if networkMode is "bridge" then
      set nic to {mode:bridged, address:mac}
      if bridgeName is not "auto" then set nic to {mode:bridged, address:mac, host interface:bridgeName}
    end if
    set vm to make new virtual machine with properties {backend:apple, configuration:{name:vmName, memory:(mem as integer), cpu cores:(cpus as integer), drives:{{guest size:(diskMiB as integer)}, {source:iso}}, network interfaces:{nic}, displays:{{dynamic resolution:true}}}}
    return id of vm
  end tell
end run
' $name $installer_iso ($memory | into string) ($cpus | into string) (($disk_size * 1024) | into string) $mac $bridge_interface $install_network)
  if ($config | path type) != 'file' {
    error make {msg: $"VM bundle not found at ($bundle)"}
  }

  # UTM cannot open a removable drive attached with AppleScript. The ISO is
  # therefore a normal drive, copied into the bundle as the second drive.
  # The VM disk is /dev/vda. Make the ISO copy writable for Virtualization.
  let iso_image = ($bundle | path join 'Data' ($installer_iso | path basename))
  ^chmod 644 $iso_image

  # The AppleScript interface does not expose these settings.
  # By default UTM creates a headless VM with no keyboard or pointer.
  plist-set $config 'Virtualization:Rosetta' bool 'true'
  plist-set $config 'Virtualization:Keyboard' string Generic
  plist-set $config 'Virtualization:Pointer' string Mouse
  plist-set $config 'Virtualization:ClipboardSharing' bool 'true'
  plist-set $config 'Virtualization:Audio' bool 'true'

  # Remove the unused serial pty: a full hvc0 buffer makes the guest hang.
  loop {
    let result = (^/usr/libexec/PlistBuddy -c 'Delete :Serial:0' $config | complete)
    if $result.exit_code != 0 { break }
  }

  start-vm $vm_id

  step 'Waiting for the installer to get an IP address'
  let ip = if $install_network == "shared" { wait-for-ip $mac $leases } else { guest-ip $vm_id $mac }
  print --stderr $"IP address: ($ip)"
  let target = $"root@($ip)"
  wait-for-ssh $target

  let addresses = (^ssh ...$SSH_OPTS $target 'cat /sys/class/net/*/address' | lines)
  if $mac not-in $addresses {
    error make {msg: $"SSH target ($ip) does not have the new VM MAC address ($mac)"}
  }

  # disko.nix formats /dev/vda. Make sure it is the new, empty VM disk.
  let disk = (^ssh ...$SSH_OPTS $target lsblk -dnbo SIZE,RO /dev/vda
    | str trim | split row --regex '\s+' | into int)
  if ($disk | length) != 2 {
    error make {msg: 'cannot read /dev/vda size and read-only status'}
  }
  if $disk.0 != ($disk_size * 1024 * 1024 * 1024) or $disk.1 != 0 {
    error make {msg: $"/dev/vda is not the VM disk \(size ($disk.0), read-only ($disk.1)\)"}
  }

  step $"Installing ($flake)#($attr) with nixos-anywhere"
  mut anywhere_args = [
    --flake $"($flake)#($attr)"
    --target-host $target
    --build-on remote
    --phases 'disko,install'
  ]
  if $extra_files != null {
    $anywhere_args = ($anywhere_args | append [--extra-files ($extra_files | path expand)])
  }
  ^nixos-anywhere ...$anywhere_args

  step 'Removing the installer ISO'
  # A disconnect while powering off is expected.
  let poweroff = (^ssh ...$SSH_OPTS $target systemctl poweroff | complete)
  wait-for-status $vm_id stopped
  applescript '
on run argv
  tell application "UTM"
    set vm to virtual machine id (item 1 of argv)
    set cfg to configuration of vm
    set drives of cfg to {{id:id of item 1 of drives of cfg}}
    update configuration of vm with cfg
  end tell
end run
' $vm_id | ignore
  rm --force $iso_image

  if $network == 'none' {
    ^/usr/libexec/PlistBuddy -c 'Delete :Network:0' $config
  }
  start-vm $vm_id
  if $network == 'none' {
    print --stderr $"Done. VM '($name)' started with networking disabled."
    return
  }

  step 'Waiting for the installed system'
  let installed_ip = if $install_network == "shared" { $ip } else { guest-ip $vm_id $mac }
  wait-for-ssh $"($env.USER)@($installed_ip)"

  print --stderr $"
Done. VM '($name)' runs ($flake)#($attr) at ($installed_ip).

  ssh ($installed_ip)

Reserve MAC address ($mac) on the DHCP server to keep this address.
"
}
