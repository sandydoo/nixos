{
  writeShellApplication,
  writeTextDir,
  nushell,
  nixos-anywhere,
  openssh,
}:

let
  script = writeTextDir "utm-install" (builtins.readFile ./utm-install.nu);
in
writeShellApplication {
  name = "utm-install";
  # osascript and PlistBuddy come from macOS.
  runtimeInputs = [
    nixos-anywhere
    openssh
  ];
  text = ''
    exec ${nushell}/bin/nu --no-config-file ${script}/utm-install "$@"
  '';
}
