{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.10.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      hash = "sha256-ND3Kb1u0B5O+joNCvE4LzJjYpSFnt5QWDFGmuAmYns8=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      hash = "sha256-epaG0urTx3nqr2mIClkDLzrxf+gOZE4EDyC0YyEPq8M=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      hash = "sha256-70O4DI3+7ZuZstem8QeiL/qrj9M65nYVflqzqUlpnSY=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      hash = "sha256-cdiwcZPevnbhlpsHzPeRVsb5WQdunaNlTCKh+XwarUU=";
    };
  };

  source = sources.${stdenvNoCC.hostPlatform.system} or (throw "hunk: unsupported platform ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "hunk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/modem-dev/hunk/releases/download/v${version}/${source.asset}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = source.asset;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 hunk $out/bin/hunk
    runHook postInstall
  '';

  meta = {
    description = "Review-first terminal diff viewer for agentic coders";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
