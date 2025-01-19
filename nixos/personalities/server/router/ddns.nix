{ config, lib, ... }:
let
  firstBindAddress = lib.head config.services.bind.listenOn;
in
{
  sops.secrets.cfApiToken = {
    sopsFile = ../../../../secrets/users.yaml;
  };
  sops.secrets."bind-ddns-tsig-file" = {
    sopsFile = ../../../../secrets/users.yaml;
    owner = config.systemd.services.bind.serviceConfig.User;
    group = config.systemd.services.bind.serviceConfig.User;
  };
  sops.secrets."ddns-tsig-key" = {
    # TODO: poor secret name
    sopsFile = ../../../../secrets/users.yaml;
    owner = config.systemd.services.kea-dhcp-ddns-server.serviceConfig.User;
    group = config.systemd.services.kea-dhcp-ddns-server.serviceConfig.User;
  };
  services.cloudflare-dyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cfApiToken.path;
  };

  services.bind.extraConfig = ''
    include "${config.sops.secrets."bind-ddns-tsig-file".path}";
  '';

  services.kea.dhcp-ddns = {
    enable = true;
    settings = {
      tsig-keys = [
        {
          name = "dhcp-update-key";
          algorithm = "hmac-sha256";
          secret-file = "${config.sops.secrets."ddns-tsig-key".path}";
        }
      ];
      forward-ddns = {
        ddns-domains = [
          {
            name = "${config.networking.domain}.";
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = "${firstBindAddress}";
              port = 53;
            }];
          }
        ];
      };
    };
  };

}
