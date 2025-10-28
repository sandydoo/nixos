final: prev: {
  cargo-nextest = prev.cargo-nextest.overrideAttrs (prev: {
    preConfigure = ''
      export PATH="$PATH:/usr/sbin"
    '';
  });
}
