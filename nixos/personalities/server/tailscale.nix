{ inputs, config, pkgs, ... }:
let
  tailScalePort = 41641;
in
{
  disabledModules = [
    "${inputs.nixpkgs}/nixos/modules/services/networking/tailscale.nix"
  ];
  # TODO: Fix when in stable.
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/tailscale.nix"
  ];
  sops.secrets = {
    tailscale-auth-key = {
      sopsFile = ../../../secrets/users.yaml;
    };
  };
  networking.firewall.allowedUDPPorts = [ tailScalePort ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  services.tailscale = {
    package = pkgs.unstable.tailscale;
    useRoutingFeatures = "client";
    enable = true;
    port = tailScalePort;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };
}
