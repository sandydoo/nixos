{
  lib,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
  testers,
}:

let
  version = "0.19.0";

  sources = {
    "x86_64-linux" = {
      asset = "hunkdiff-linux-x64";
      hash = "sha256-1NlC/twFuLtRc+KRPlRUBqXZQSug3biPjn9NzXf9BgI=";
    };
    "aarch64-linux" = {
      asset = "hunkdiff-linux-arm64";
      hash = "sha256-L13CVfv0fVlO0xr97AiPAoMeRCKB1VQFkwFjyOIKXt8=";
    };
    "x86_64-darwin" = {
      asset = "hunkdiff-darwin-x64";
      hash = "sha256-43lGDNDszL0PEJuYve3KEpBVz/+gALxo3YJVUxYW2zE=";
    };
    "aarch64-darwin" = {
      asset = "hunkdiff-darwin-arm64";
      hash = "sha256-fuzmmCyxRhwMIvnXCkGw+4CU2WXvAtwi+DirwN5xpCk=";
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
        inherit meta passthru;
      }
    else
      hunk-unwrapped.overrideAttrs { inherit meta passthru; };
in
hunk
