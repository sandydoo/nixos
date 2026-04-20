{ pkgs, ... }:

{
  services.datadog-agent = {
    enable = false;
    enableTraceAgent = true;
    site = "datadoghq.eu";
    apiKeyFile = "/run/datadog-agent";
    package = pkgs.datadog-agent.override { extraTags = [ "otlp" ]; };
    extraConfig = {
      logs_enabled = true;
      otlp_config = {
        receiver = {
          protocols = {
            http.endpoint = "localhost:4318";
            grpc.endpoint = "localhost:4317";
          };
        };
      };
    };
  };
}
