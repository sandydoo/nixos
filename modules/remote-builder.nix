{
  users.users.remotebuilder = {
    isNormalUser = true;
    createHome = false;
    group = "remotebuilder";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkIlj+aHsr4zs3mCmnpdQNpc6YYYcXioW+RMdO80pF/ builder@localhost"
    ];
  };

  users.groups.remotebuilder = { };

  nix.settings.trusted-users = [ "remotebuilder" ];
}
