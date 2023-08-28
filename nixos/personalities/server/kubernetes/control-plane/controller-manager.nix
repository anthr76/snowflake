{ config }:
{
  services.kubernetes.controllerManager = {
    enable = true;
    bindAddress = "0.0.0.0";
    serviceAccountKeyFile = config.sops.secrets.controller-manager-service-account-key.path;
  };
}
