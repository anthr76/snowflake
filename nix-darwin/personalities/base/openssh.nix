{
  outputs,
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (config.networking) hostName;
  hosts = outputs.nixosConfigurations;
  pubKey = host: ../../../nixos/hosts/${host}/ssh_host_ed25519_key.pub;
in {
  programs.ssh = {
    # Each hosts public key
    knownHosts =
      builtins.mapAttrs (name: _: {
        publicKeyFile = pubKey name;
      })
      hosts;
  };

  #TODO: Yubikey agent with MacOS is really wonky figure out best way to handle

  environment.systemPackages = [pkgs.yubikey-agent pkgs.yubico-piv-tool];
}
