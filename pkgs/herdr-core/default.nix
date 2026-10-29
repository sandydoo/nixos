{
  lib,
  stdenvNoCC,
  fetchurl,
  testers,
}:

let
  version = "0.1.17";

  sources = {
    "x86_64-linux" = {
      target = "linux-x86_64";
      hash = "sha256-guxEBD9olL/bcWuXm4fNpD/X+kawEE57e9k+ZNGpuHc=";
    };
    "aarch64-linux" = {
      target = "linux-aarch64";
      hash = "sha256-OjekVOxjSUz0MG2yZIH+nblmc9iIcjcB0k+KmSroq4w=";
    };
    "x86_64-darwin" = {
      target = "macos-x86_64";
      hash = "sha256-4twyEe2x8cd9DnPddsFCZjbXEFDzSlMDkWpW02PXBis=";
    };
    "aarch64-darwin" = {
      target = "macos-aarch64";
      hash = "sha256-ztvU1Nm6E4VYgZjdTTxn0mVEePM63VtkRdTQ652l/PM=";
    };
  };

  source =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "herdr-core: unsupported platform ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${version}/herdr-core-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # Preserve the upstream macOS signature and the static Linux binaries.
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-core "$out/bin/herdr-core"
    ln -s herdr-core "$out/bin/hc"
    install -Dm644 LICENSE "$out/share/licenses/herdr-core/LICENSE"
    install -Dm644 THIRD-PARTY-NOTICES "$out/share/licenses/herdr-core/THIRD-PARTY-NOTICES"
    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    inherit version;
  };

  meta = {
    description = "Persistent terminals for running and coordinating coding agents";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    mainProgram = "hc";
    platforms = lib.attrNames sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
