{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  testers,
}:

let
  version = "0.14.1";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      hash = "sha256-enmhID6L4tr8+KDgvi8XvJhMsFC+GVoHEKh3YkSqiP4=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      hash = "sha256-AABJX6sEBfRGn2f46jPbkGbwCZcvcETzIXUKbRneHE4=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      hash = "sha256-XgaqFSGJWfEDj9VRVwXvoN9qaBhYxBDuuoAEdvf8FNI=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      hash = "sha256-nosD+2bj4PoSX+fQSw/X9ct+8/c07p840wB9FQp3mR8=";
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
        inherit meta passthru;
      }
    else
      hunk-unwrapped.overrideAttrs { inherit meta passthru; };
in
hunk
