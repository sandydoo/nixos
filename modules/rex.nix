{
  config,
  inputs,
  user,
  ...
}:

{
  imports = [ inputs.rex.nixosModules.default ];

  services.rex = {
    enable = true;
    inherit user;
    group = config.users.users.${user}.group;
    socketMode = "0600";
    tailscaleServe.enable = true;
    tailnetAllowIdentified = true;
  };

  services.tailscale = {
    extraUpFlags = [ "--advertise-tags=tag:rex" ];
    serve = {
      enable = true;
      services."${config.networking.hostName}-rex" = {
        endpoints."tcp:443" = "https://unix:${config.services.rex.tailscaleServe.socketPath}";
      };
    };
  };

  systemd.services.tailscale-serve = {
    after = [ "rex-tailscale-serve.service" ];
    requires = [ "rex-tailscale-serve.service" ];
    partOf = [ "rex-tailscale-serve.service" ];
  };
}
