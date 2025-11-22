{ outputs, lib, config, pkgs, ... }:

let
  inherit (config.networking) hostName;
  hosts = outputs.nixosConfigurations;

  # Check if impermanence is enabled
  # Use builtins.hasAttr to safely check without causing evaluation errors
  hasOptinPersistence = builtins.hasAttr "persistence" config.environment
    && config.environment.persistence ? "/persist";
in {
  services.openssh = {
    enable = true;
    settings = {
      # Harden
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      # Automatically remove stale sockets
      StreamLocalBindUnlink = "yes";
      # Allow forwarding ports to everywhere
      GatewayPorts = "clientspecified";
    };

    hostKeys = [
      {
        path = "${lib.optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "${lib.optionalString hasOptinPersistence "/persist"}/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
  };

  programs.ssh = {
    # Each hosts public key
    knownHosts =
      builtins.mapAttrs (name: cfg: {
        publicKeyFile = ../../hosts/${name}/ssh_host_ed25519_key.pub;
        extraHostNames =
          [
            cfg.config.networking.fqdn
          ]
          ++
          # Alias for localhost if it's the same host
          (lib.optional (name == hostName) "localhost");
      })
      hosts;
  };

  # Passwordless sudo when SSH'ing with keys
  security.pam.sshAgentAuth = {
    enable = true;
    authorizedKeysFiles = ["/etc/ssh/authorized_keys.d/%u"];
  };
}
