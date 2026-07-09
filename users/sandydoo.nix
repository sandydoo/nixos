{
  pkgs,
  isLinux,
  user,
  ...
}:

{
  users.users.${user} = {
    isNormalUser = true;
    home = if isLinux then "/home/${user}" else "/Users/${user}";
    description = "Sander";
    extraGroups = [
      "wheel"
      "docker"
      "libvirtd"
      "postgres"
      "video"
      "input"
    ];
    shell = pkgs.fish;
    hashedPassword = "$6$0v8AhbJr0C8TH5Dq$dsxXIZGLgoL2thXhBBPlCiiSiWKo.MZxIHX.9j71ZeHwQcm.rdXQZXtP.acuXXD4A7ifUexMuIzCkUNG5LUWO1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO18rhoNZWQZeudtRFBZvJXLkHEshSaEFFt2llG5OeHk hey@sandydoo.me"
    ];
  };
}
