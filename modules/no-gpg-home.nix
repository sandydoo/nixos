{ lib, ... }:

{
  programs.gpg.enable = lib.mkForce false;
  programs.gpg.publicKeys = lib.mkForce [ ];
}
