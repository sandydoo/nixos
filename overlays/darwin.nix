let
  fixOpencode =
    pkgs: opencode:
    opencode.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        # Bun 1.3.12+ leaves an invalid Mach-O signature on compiled
        # executables. Sign before opencode's build-time smoke test runs.
        substituteInPlace packages/opencode/script/build.ts \
          --replace-fail \
            '    const binaryPath = `dist/''${name}/bin/opencode`' \
            '    const binaryPath = `dist/''${name}/bin/opencode`
            await $`${pkgs.lib.getExe pkgs.rcodesign} sign --code-signature-flags linker-signed ''${binaryPath}`'
      '';

      # bun build --compile appends the JavaScript bundle to the executable.
      dontStrip = true;
    });
in
final: prev: {
  bclm = final.callPackage ../pkgs/bclm { };
  latest = prev.latest.extend (
    latestFinal: latestPrev: {
      opencode = fixOpencode latestFinal latestPrev.opencode;
    }
  );
  opencode = fixOpencode final prev.opencode;
  xdr-boost = final.callPackage ../pkgs/xdr-boost { };
}
