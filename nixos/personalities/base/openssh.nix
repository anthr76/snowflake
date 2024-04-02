{ outputs, lib, config, ... }:

let
  inherit (config.networking) hostName;
  hosts = outputs.nixosConfigurations;
  pubKey = host: ../../hosts/${host}/ssh_host_ed25519_key.pub;
in {
  services.openssh = {
    enable = true;
    settings = {
      # Harden
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
    };

    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  programs.ssh = {
    # Each hosts public key
    knownHosts = builtins.mapAttrs (name: _: {
      publicKeyFile = pubKey name;
      extraHostNames = (lib.optional (name == hostName) "localhost");
    }) hosts;
  };
  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = true;
}
