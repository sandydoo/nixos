final: prev: {
  haskell = prev.haskell // {
    packages = prev.haskell.packages // {
      ghc925 = prev.haskell.packages.ghc925.override {
        overrides = hfinal: hprev: {
          ListLike = prev.haskell.lib.dontCheck hprev.ListLike;
        };
      };
    };
  };

  # mesa = final.latest.mesa;
}
