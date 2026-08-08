{
  buildFHSEnv,
  fetchurl,
  lib,
  stdenvNoCC,
  testers,
}:

let
  version = "17.3.0";

  sources = {
    "x86_64-linux" = {
      asset = "omp-linux-x64";
      hash = "sha256-KH8HNm8piW7x40VCPat5uCqNwMFZM4PiDf3WKp3S55k=";
    };
    "aarch64-linux" = {
      asset = "omp-linux-arm64";
      hash = "sha256-j/1tTQuAA7Qiirzazo7TiC2pgeltmubBklXMRLZ/jzc=";
    };
    "x86_64-darwin" = {
      asset = "omp-darwin-x64";
      hash = "sha256-eyp0m1M1ShQVfybwBqpPudtNTSczIEisRjOLybqezNs=";
    };
    "aarch64-darwin" = {
      asset = "omp-darwin-arm64";
      hash = "sha256-8+V2lIxke18U5M6vB9iuv2F72kIpDHperBiG+0wLE/Y=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "oh-my-pi: unsupported platform ${stdenvNoCC.hostPlatform.system}");

  oh-my-pi-unwrapped = stdenvNoCC.mkDerivation {
    pname = "oh-my-pi-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/${source.asset}";
      inherit (source) hash;
    };

    dontUnpack = true;
    dontFixup = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/omp"
      runHook postInstall
    '';

    meta.mainProgram = "omp";
  };

  meta = {
    description = "Terminal-based coding agent with multi-model support";
    homepage = "https://omp.sh";
    changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };

  passthru.tests.version = testers.testVersion {
    package = oh-my-pi;
    inherit version;
  };

  oh-my-pi =
    if stdenvNoCC.hostPlatform.isLinux then
      buildFHSEnv {
        name = "omp";
        runScript = lib.getExe oh-my-pi-unwrapped;
        targetPkgs = pkgs: [
          pkgs.alsa-lib
          pkgs.libopus
          pkgs.libpulseaudio
          pkgs.stdenv.cc.cc.lib
        ];
        inherit meta passthru;
      }
    else
      oh-my-pi-unwrapped.overrideAttrs {
        pname = "oh-my-pi";
        inherit meta passthru;
      };
in
oh-my-pi
