# Create a UTM VM (Apple Virtualization backend) and install a NixOS
# configuration from a flake onto it with nixos-anywhere.
#
# Steps:
#   1. Build the installer ISO (nixosConfigurations.nixos-utm-installer).
#   2. Create the VM with AppleScript and enable Rosetta in config.plist.
#   3. Boot the ISO and find the VM IP in the vmnet DHCP leases.
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

# Create a UTM VM and install NixOS onto it with nixos-anywhere.
def main [
  --name: string = 'nixos-utm' # UTM VM name
  --flake: string = '.' # Flake that has the configuration
  --attr: string = 'nixos-utm' # nixosConfigurations attribute to install
  --cpus: int = 8 # CPU cores
  --memory: int = 16384 # Memory in MiB
  --disk-size: int = 128 # Disk size in GiB
  --iso: path # Use this installer ISO instead of building one
  --extra-files: path # Copy the contents of this directory to / on the new system
] {
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
  set {vmName, isoPath, mem, cpus, diskMiB, mac} to argv
  set iso to POSIX file isoPath
  tell application "UTM"
    set vm to make new virtual machine with properties {backend:apple, configuration:{name:vmName, memory:(mem as integer), cpu cores:(cpus as integer), drives:{{guest size:(diskMiB as integer)}, {source:iso}}, network interfaces:{{mode:shared, address:mac}}, displays:{{dynamic resolution:true}}}}
    return id of vm
  end tell
end run
' $name $installer_iso ($memory | into string) ($cpus | into string) (($disk_size * 1024) | into string) $mac)
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

  applescript '
on run argv
  tell application "UTM"
    set vm to virtual machine id (item 1 of argv)
    reload configuration of vm
    start vm
  end tell
end run
' $vm_id | ignore

  step 'Waiting for the installer to get an IP address'
  let ip = (wait-for-ip $mac $leases)
  print --stderr $"IP address: ($ip)"
  let target = $"root@($ip)"
  wait-for-ssh $target

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
    start vm
  end tell
end run
' $vm_id | ignore
  rm --force $iso_image

  step 'Waiting for the installed system'
  wait-for-ssh $"($env.USER)@($ip)"

  print --stderr $"
Done. VM '($name)' runs ($flake)#($attr) at ($ip).

  ssh ($ip)

To keep this IP address, add the MAC address ($mac) to /etc/bootptab.
See README.md.
"
}
