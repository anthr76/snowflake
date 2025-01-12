{ config, ... }:
{
  sops.secrets.cfApiToken = {
    sopsFile = ../../../../secrets/users.yaml;
  };
  sops.secrets.ddns-tsig-key = {
    # TODO: poor secret name
    sopsFile = ../../../../secrets/users.yaml;
    owner = config.systemd.services.kea-dhcp-ddns-server.serviceConfig.User;
    group = config.systemd.services.kea-dhcp-ddns-server.serviceConfig.User;
  };
  services.cfdyndns = {
    enable = true;
    apiTokenFile = config.sops.secrets.cfApiToken.path;
  };

  services.kea.dhcp-ddns = {
    enable = true;
    settings = {
      tsig-keys = [
        {
          name = "kea";
          algorithm = "hmac-sha512";
          secret-file = "${config.sops.secrets."ddns-tsig-key".path}";
        }
      ];
      forward-ddns = {
        ddns-domains = [
          {
            name = "${config.networking.domain}.";
            key-name = "kea";
            dns-servers = [{
              hostname = "";
              ip-address = "127.0.0.1";
              port = 53;
            }];
          }
        ];
      };
      reverse-ddns = {
        ddns-domains = [
          {
            name = "168.192.in-addr.arpa.";
            key-name = "kea";
            dns-servers = [{
              hostname = "";
              ip-address = "127.0.0.1";
              port = 53;
            }];
          }
          {
            name = "10.in-addr.arpa";
            key-name = "kea";
            dns-servers = [{
              hostname = "";
              ip-address = "127.0.0.1";
              port = 53;
            }];
          }
        ];
      };
    };
  };

}
