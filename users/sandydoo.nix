{
  pkgs,
  isLinux,
  systemUser,
  ...
}:

{
  users.users.${systemUser} = {
    isNormalUser = true;
    home = if isLinux then "/home/${systemUser}" else "/Users/${systemUser}";
    description = "Sander";
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "postgres"
    ];
    shell = pkgs.fish;
    hashedPassword = "$6$0v8AhbJr0C8TH5Dq$dsxXIZGLgoL2thXhBBPlCiiSiWKo.MZxIHX.9j71ZeHwQcm.rdXQZXtP.acuXXD4A7ifUexMuIzCkUNG5LUWO1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me"
    ];
  };
}
