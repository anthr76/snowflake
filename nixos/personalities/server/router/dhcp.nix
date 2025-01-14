{config, ...}:
{

  sops.secrets.ddns-tsig-key = {
    # TODO: poor secret name
    sopsFile = ../../../../secrets/users.yaml;
  };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      dhcp-ddns.enable-updates = true;
      ddns-replace-client-name = "when-not-present";
      ddns-update-on-renew = true;
      ddns-override-client-update = true;
      ddns-override-no-update = true;
      ddns-qualifying-suffix = "${config.networking.domain}";
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;
    };
  };
  # TODO: IPV6
  services.radvd = {
    enable = false;
    config = ''
      interface vlan100 {
          IgnoreIfMissing on;
          AdvDefaultPreference high;
          MaxRtrAdvInterval 600;
          AdvReachableTime 0;
          AdvIntervalOpt on;
          AdvSendAdvert on;
          AdvOtherConfigFlag off;
          AdvRetransTimer 0;
          AdvCurHopLimit 64;
          prefix ::/0 {
              AdvAutonomous on;
              AdvValidLifetime 2592000;
              AdvOnLink on;
              AdvPreferredLifetime 14400;
              DeprecatePrefix off;
              DecrementLifetimes off;
          };
      };

    '';
  };
}
