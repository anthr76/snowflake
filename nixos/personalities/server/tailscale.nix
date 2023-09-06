{ inputs, config, ... }:
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
  services.tailscale = {
    enable = true;
    port = tailScalePort;
    authKeyFile = config.sops.secrets.tailscale-auth-key.path;
  };
}
