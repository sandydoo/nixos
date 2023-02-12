final: prev: {
  haskell = prev.haskell // {
    packages = let
      # Workaround for https://github.com/NixOS/nixpkgs/issues/140774
      fixHls = hfinal: hprev:
        let
          fixCyclicReference = p:
            prev.haskell.lib.overrideCabal p (_: {
              enableSeparateBinOutput = false;
            });
        in {
          fourmolu = hfinal.fourmolu_0_9_0_0;
          fourmolu_0_9_0_0 = fixCyclicReference hprev.fourmolu_0_9_0_0;
          ormolu = hfinal.ormolu_0_5_0_1;
          ormolu_0_5_0_1 = fixCyclicReference hprev.ormolu_0_5_0_1;
          ghcid = fixCyclicReference hprev.ghcid;
        };
    in prev.haskell.packages // {
      ghc8107 = prev.haskell.packages.ghc8107.override {
        overrides = fixHls;
      };
      ghc925 = prev.haskell.packages.ghc925.override {
        overrides = fixHls;
      };
    };
  };
}
