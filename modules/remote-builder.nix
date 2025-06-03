{
  users.users.remotebuilder = {
    isNormalUser = true;
    createHome = false;
    group = "remotebuilder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKY+NOCO6HAas0N9NTHSC6pD4m/5sIIdPvLGdRCk5R6h remotebuilder@localhost"
    ];
  };

  users.groups.remotebuilder = { };

  nix.settings.trusted-users = [ "remotebuilder" ];
}
