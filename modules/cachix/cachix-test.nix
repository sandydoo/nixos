
{
  nix.settings = {
    substituters = [
      "https://cachix-test.cachix.org"
    ];
    trusted-public-keys = [
      "cachix-test.cachix.org-1:vBABBNe24kTznC3irYprL3w12YYqpd3OqLnsnLeiCRg="
    ];
  };
}
