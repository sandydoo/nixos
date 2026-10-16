{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  testers,
}:

let
  version = "0.24.0-beta.1";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      hash = "sha256-TYGo+9et18zISlzRlKFDYySoifl4Me2iChOG4pc0uLI=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      hash = "sha256-inPVt5loM7OU8qQ+I5TNtm8Spr5lU5HHcoP0IHoCKaM=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      hash = "sha256-ABRXxExSCm6nYNFat0VSQr8Xn3IF7MYn1NuPp+A4U0w=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      hash = "sha256-UVmKF5krjYZBdUCdQKklK9/Cq8rB86mSGUmcrVWTKEw=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "hunk: unsupported platform ${stdenvNoCC.hostPlatform.system}");

  hunk-unwrapped = stdenvNoCC.mkDerivation {
    pname = "hunk-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${source.asset}.tar.gz";
      inherit (source) hash;
    };

    sourceRoot = source.asset;

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 hunk $out/bin/hunk
      # Review commands respawn the TUI through the hunkdiff alias.
      ln -s hunk $out/bin/hunkdiff
      # hunk resolves its bundled review skill by walking up ancestor dirs of
      # the binary looking for skills/hunk-review/SKILL.md.
      cp -r skills $out/skills
      runHook postInstall
    '';

    meta.mainProgram = "hunk";
  };

  meta = {
    description = "Review-first terminal diff viewer for agentic coders";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  passthru.tests.version = testers.testVersion {
    package = hunk;
    inherit version;
  };

  # The release artifact is a Bun runtime with the application appended as a trailer.
  hunk =
    if stdenvNoCC.hostPlatform.isLinux then
      buildFHSEnv {
        name = "hunk";
        runScript = lib.getExe hunk-unwrapped;
        targetPkgs = pkgs: [ pkgs.stdenv.cc.cc.lib ];
        extraInstallCommands = ''
          ln -s hunk $out/bin/hunkdiff
        '';
        inherit meta passthru;
      }
    else
      hunk-unwrapped.overrideAttrs { inherit meta passthru; };
in
hunk
