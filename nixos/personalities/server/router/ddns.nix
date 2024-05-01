{ config, ... }:
{
  sops.secrets.cfApiToken = {
    sopsFile = ../../../../secrets/users.yaml;
  };
  services.cfdyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cfApiToken.path;
  };
}
