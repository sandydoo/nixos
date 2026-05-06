final: prev: {
  bclm = final.callPackage ../pkgs/bclm { };

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
