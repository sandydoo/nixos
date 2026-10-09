final: prev: {
  eternal-terminal = prev.eternal-terminal.overrideAttrs (
    old:
    final.lib.optionalAttrs final.stdenv.hostPlatform.isLinux {
      postPatch = (old.postPatch or "") + ''
        # Match the C++20 standard used by Abseil on Linux.
        substituteInPlace CMakeLists.txt \
          --replace-fail 'set(CMAKE_CXX_STANDARD 17)' 'set(CMAKE_CXX_STANDARD 20)'
      '';
    }
  );

  hunk = final.callPackage ../pkgs/hunk { };
  oh-my-pi = final.callPackage ../pkgs/oh-my-pi { };

  secretspec = prev.secretspec.overrideAttrs {
    NO_GRAPHICS = "1";
  };

  streamlink = prev.streamlink.overridePythonAttrs (old: {
    disabledTests =
      (old.disabledTests or [ ])
      ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [
        # requires Linux-only socket.SO_BINDTODEVICE
        "test_set_interface[unix-iface]"
        "test_set_interface[unix-iface-prefix]"
        "test_set_interface[unix-ifhost-prefix]"
        "test_set_interface[unix-ifhost-prefix-invalid]"
      ];
  });
}
