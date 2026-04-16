final: prev: {
  xdr-boost = final.swiftPackages.stdenv.mkDerivation {
    pname = "xdr-boost";
    version = "0-unstable-2025-04-02";

    src = final.fetchFromGitHub {
      owner = "levelsio";
      repo = "xdr-boost";
      rev = "2f2f20b4c6241243a3a652b9c7be5ec506212bb2";
      hash = "sha256-n/kFrEPjrjrTuPmBVynMVdsdJ3hPkYLRD4TnLvxUZVc=";
    };

    nativeBuildInputs = [ final.swiftPackages.swift ];

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

    meta = with final.lib; {
      description = "Boost the brightness of MacBook XDR displays to 1600 nits";
      homepage = "https://github.com/levelsio/xdr-boost";
      license = licenses.mit;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "xdr-boost";
    };
  };
}
