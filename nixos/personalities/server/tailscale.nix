{ config, ... }:
{
  sops.secrets = {
    tailscale-auth-key = { sopsFile = ../../../secrets/users.yaml; };
  };
  services.tailscale = {
    useRoutingFeatures = "both";
    extraUpFlags = [ "--accept-routes" "--reset" ];
    openFirewall = true;
    enable = true;
    port = 41641;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };
}
