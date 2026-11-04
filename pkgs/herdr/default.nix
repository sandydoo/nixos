{
  lib,
  stdenvNoCC,
  stdenv,
  fetchurl,
  testers,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  fontconfig,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  herdr-core,
  component ? "app",
}:

let
  releases = {
    core = {
      pname = "herdr-core";
      version = "0.1.19";
      sources = {
        "x86_64-linux" = {
          target = "linux-x86_64";
          hash = "sha256-Stz7Qj1S8kxcxKHizS/K0fYtKLt3h2rEcsKQgqPqpCQ=";
        };
        "aarch64-linux" = {
          target = "linux-aarch64";
          hash = "sha256-+Vw0/XF37ViAfXT+TueLs9xz6zfyHGlJYGQACiGryxA=";
        };
        "x86_64-darwin" = {
          target = "macos-x86_64";
          hash = "sha256-L5W+2uLKG/n5YR1hBm7zrCEcYsoIKCEy1I4oe22hTQg=";
        };
        "aarch64-darwin" = {
          target = "macos-aarch64";
          hash = "sha256-UzjZAK2tttJzucjpcCckfbMXnM/+3hCheTNY8W4I1oM=";
        };
      };
    };
    app = {
      pname = "herdr";
      version = "0.1.14";
      sources = {
        "x86_64-linux" = {
          target = "linux-x86_64";
          hash = "sha256-R1o4P49DnjGRqGY1tcEobOTf0tn83x58vf3Wxxdvj/M=";
        };
        "aarch64-linux" = {
          target = "linux-aarch64";
          hash = "sha256-MKQxzpXBc1bv6K/tUMTq+IiNg+9FrNmqkRCU1RcH0Ac=";
        };
        "aarch64-darwin" = {
          target = "macos-aarch64";
          hash = "sha256-DabKIUIUOJyjngX99lI/1uS+QjpL59/Tm2d9aKQQ+os=";
        };
      };
    };
  };
  release = releases.${component};
  isApp = component == "app";
  isLinuxApp = isApp && stdenvNoCC.hostPlatform.isLinux;
  source =
    release.sources.${stdenvNoCC.hostPlatform.system}
      or (throw "${release.pname}: unsupported platform ${stdenvNoCC.hostPlatform.system}");
  desktopItem = makeDesktopItem {
    name = "herdr-app";
    desktopName = "Herdr";
    comment = "Terminals and coding agents that keep running";
    exec = "herdr-app";
    icon = "herdr-app";
    terminal = false;
    categories = [ "Development" ];
    startupWMClass = "herdr-app";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  inherit (release) pname version;

  src = fetchurl {
    url = "https://releases.herdr.dev/${component}/${release.version}/herdr-${
      if isApp then "app" else "core"
    }-${source.target}.tar.gz";
    inherit (source) hash;
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  # Preserve the upstream macOS signatures and the static core binaries.
  dontFixup = !isLinuxApp;
  dontStrip = true;

  nativeBuildInputs = lib.optionals isLinuxApp [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = lib.optionals isLinuxApp [
    fontconfig
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];
  runtimeDependencies = lib.optionals isLinuxApp [
    (lib.getLib vulkan-loader)
    (lib.getLib wayland)
  ];

  installPhase = ''
    runHook preInstall
  ''
  + (
    if !isApp then
      (
        if stdenvNoCC.hostPlatform.isDarwin then
          ''
            mkdir -p "$out/Applications" "$out/bin"
            cp -R "Herdr Core.app" "$out/Applications/Herdr Core.app"
            ln -s "$out/Applications/Herdr Core.app/Contents/MacOS/herdr-core" "$out/bin/herdr-core"
          ''
        else
          ''
            install -Dm755 herdr-core "$out/bin/herdr-core"
          ''
      )
      + ''
        ln -s herdr-core "$out/bin/hc"
        install -Dm644 LICENSE "$out/share/licenses/herdr-core/LICENSE"
        install -Dm644 THIRD-PARTY-NOTICES "$out/share/licenses/herdr-core/THIRD-PARTY-NOTICES"
      ''
    else
      ''
        mkdir -p "$out/bin"
        ln -s ${herdr-core}/bin/herdr-core "$out/bin/herdr-core"
        ln -s herdr-core "$out/bin/hc"
      ''
      + (
        if stdenvNoCC.hostPlatform.isDarwin then
          ''
            mkdir -p "$out/Applications"
            cp -R Herdr.app "$out/Applications/Herdr.app"
            ln -s "$out/Applications/Herdr.app/Contents/MacOS/Herdr" "$out/bin/herdr-app"
          ''
        else
          ''
            mkdir -p "$out/lib/herdr"
            cp -R herdr-app/. "$out/lib/herdr/"
            makeWrapper "$out/lib/herdr/herdr-app" "$out/bin/herdr-app" \
              --prefix PATH : ${lib.makeBinPath [ herdr-core ]}
            install -Dm644 herdr-app/herdr-app.svg "$out/share/icons/hicolor/scalable/apps/herdr-app.svg"
            install -Dm644 ${desktopItem}/share/applications/herdr-app.desktop "$out/share/applications/herdr-app.desktop"
          ''
      )
  )
  + ''
    runHook postInstall
  '';

  passthru.tests = lib.optionalAttrs (!isApp) {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      inherit (release) version;
    };
  };

  meta = {
    description =
      if isApp then
        "Native app for terminals and coding agents"
      else
        "Persistent terminals for running and coordinating coding agents";
    homepage = "https://github.com/herdrdev/herdr-${component}";
    license = lib.licenses.asl20;
    mainProgram = if isApp then "herdr-app" else "hc";
    platforms = lib.attrNames release.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
