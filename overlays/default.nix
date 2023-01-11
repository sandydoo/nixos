final: prev: {
  haskell = prev.haskell // {
    packages = let
      # https://github.com/tweag/ormolu/issues/927
      fixHls = hfinal: hprev:
        let
          fixOrmolu = p: prev.lib.pipe p [
            (prev.haskell.lib.compose.addExtraLibrary hprev.file-embed)
            (prev.haskell.lib.compose.disableCabalFlag "fixity-th")
          ];
        in {
          fourmolu = hfinal.fourmolu_0_9_0_0;
          fourmolu_0_9_0_0 = fixOrmolu hprev.fourmolu_0_9_0_0;
          ormolu = hfinal.ormolu_0_5_0_1;
          ormolu_0_5_0_1 = fixOrmolu hprev.ormolu_0_5_0_1;
        };
    in prev.haskell.packages // {
      ghc8107 = prev.haskell.packages.ghc8107.override {
        overrides = fixHls;
      };
      ghc925 = prev.haskell.packages.ghc925.override {
        overrides = hfinal: hprev: {
          ListLike = prev.haskell.lib.dontCheck hprev.ListLike;
        };
      };
    };
  };
}
