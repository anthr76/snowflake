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
  pkcs11Whitelist = "/nix/store/*";
  sshAgentWrapper = pkgs.writeShellScript "ssh-agent-wrapper" ''
    # Remove stale socket if it exists
    rm -f "$HOME/.ssh/agent.sock"
    exec ${pkgs.openssh}/bin/ssh-agent -D -a "$HOME/.ssh/agent.sock" -P "${pkcs11Whitelist}"
  '';
in {
  programs.ssh = {
    # Each hosts public key
    knownHosts =
      builtins.mapAttrs (name: _: {
        publicKeyFile = pubKey name;
      })
      hosts;
  };

  environment.systemPackages = [pkgs.yubico-piv-tool];

  # OpenSSH agent with PKCS11 whitelist for YubiKey
  launchd.user.agents.ssh-agent = {
    serviceConfig = {
      Label = "org.openssh.ssh-agent";
      ProgramArguments = ["${sshAgentWrapper}"];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  environment.variables.SSH_AUTH_SOCK = "$HOME/.ssh/agent.sock";
}
