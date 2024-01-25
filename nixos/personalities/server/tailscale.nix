{ config, pkgs, ... }:
let
  tailScalePort = 41641;
in
{
  sops.secrets = {
    tailscale-auth-key = {
      sopsFile = ../../../secrets/users.yaml;
    };
  };
  networking.firewall.allowedUDPPorts = [ tailScalePort ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale = {
    package = pkgs.unstable.tailscale;
    # useRoutingFeatures = "server";
    extraUpFlags = [
      "--accept-routes"
    ];
    enable = true;
    port = tailScalePort;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };
}
