{ config, ... }:

{
  sops.secrets = {
    controller-manager-service-account-key = {
      sopsFile = ../secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
  };
  services.kubernetes.controllerManager = {
    enable = true;
    bindAddress = "0.0.0.0";
    serviceAccountKeyFile = config.sops.secrets.controller-manager-service-account-key.path;
  };
}
