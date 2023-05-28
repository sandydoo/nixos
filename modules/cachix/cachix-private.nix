
{
  nix.settings = {
    substituters = [
      "https://cachix-private.cachix.org"
    ];
    trusted-public-keys = [
      "cachix-private.cachix.org-1:3axMmTI11ok4U2nMmWX8MZsRLmQzQBuRdOJ0EszhPuY="
    ];
  };
}
