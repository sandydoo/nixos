{
  fetchFromGitHub,
  lib,
  swiftPackages,
  ...
}:

swiftPackages.stdenv.mkDerivation {
  pname = "xdr-boost";
  version = "0-unstable-2026-07-08";

  src = fetchFromGitHub {
    owner = "levelsio";
    repo = "xdr-boost";
    rev = "f1d938db8f05952d6e4fa394f1b4c1f44a47bb1a";
    hash = "sha256-PAt7RJ8iQrZiY5ry3RA7f71S9I79GtybqQu7p95N6qs=";
  };

  nativeBuildInputs = [ swiftPackages.swift ];

  buildPhase = ''
    runHook preBuild
    swiftc -O -o xdr-boost Sources/main.swift \
      -framework Cocoa -framework MetalKit -framework Metal
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 xdr-boost $out/bin/xdr-boost
    runHook postInstall
  '';

  meta = {
    description = "Boost the brightness of MacBook XDR displays to 1600 nits";
    homepage = "https://github.com/levelsio/xdr-boost";
    license = lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
    mainProgram = "xdr-boost";
  };
}
