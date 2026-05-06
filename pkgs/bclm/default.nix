{ stdenv, rustc }:

stdenv.mkDerivation {
  pname = "bclm";
  version = "0.1.0";
  src = ./src;

  nativeBuildInputs = [ rustc ];

  buildPhase = ''
    runHook preBuild
    rustc -O main.rs -o bclm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 bclm $out/bin/bclm
    runHook postInstall
  '';

  meta = {
    description = "Set Apple SMC battery charge limit (BCLM key) on Intel Macs";
    platforms = [ "x86_64-linux" ];
  };
}
