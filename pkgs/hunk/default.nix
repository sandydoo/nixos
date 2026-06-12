{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  testers,
}:

let
  version = "0.15.1";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      hash = "sha256-HWWXh1d8j2JPyVWv2ULRAkrH+wNTL7+InS8mAkr5a/k=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      hash = "sha256-HM0so9T77rA364Bzoau1/SxuDiPtPNHc//w3Cdle26I=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      hash = "sha256-Ow2kQl641Ahztn3RINefNmHgFPOnraWRTOi3CjEf2L4=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      hash = "sha256-CjzN4yiW+gzjfh1k5JBKKXnL6yepoe+rxSRPAD8+p5g=";
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
