{
  imports = [
    ../../personalities/base
    ../../personalities/server
    ../../modules/nixos/router.nix
  ];

  # Example router configuration with static DHCP reservations
  services.router = {
    enable = true;
    domain = "example.rabbito.tech";

    # Interface configuration
    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="11:22:33:44:55:66", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="77:88:99:aa:bb:cc", NAME="oob"
    '';

    # Cloudflare DDNS
    cloudflaredomains = [
      "fw-example.rabbito.tech"
      "example.rabbito.tech"
    ];

    # Tailscale routes
    tailscaleRoutes = [
      "192.168.100.0/24"
      "192.168.10.0/24"
      "10.50.99.0/24"
    ];

    # Global static reservations (work across all subnets)
    globalStaticReservations = [
      {
        hostname = "router";
        mac = "aa:bb:cc:dd:ee:ff";
        ip = "192.168.1.1";
      }
    ];

    # LAN network static reservations
    lanStaticReservations = [
      {
        hostname = "nas";
        mac = "de:ad:be:ef:ca:fe";
        ip = "192.168.1.10";
      }
      {
        hostname = "printer";
        mac = "12:34:56:78:9a:bc";
        ip = "192.168.1.20";
      }
    ];

    # OOB management network reservations
    oobStaticReservations = [
      {
        hostname = "switch-mgmt";
        mac = "ab:cd:ef:01:23:45";
        ip = "10.10.10.50";
      }
      {
        hostname = "ap-mgmt";
        mac = "98:76:54:32:10:fe";
        ip = "10.10.10.51";
      }
    ];

    # Custom DNS records for the main domain
    dnsRecords = [
      # Infrastructure services
      {
        name = "monitoring";
        type = "A";
        value = "192.168.10.10";
        ttl = 300;
      }
      {
        name = "grafana";
        type = "CNAME";
        value = "monitoring";
      }
      {
        name = "prometheus";
        type = "CNAME";
        value = "monitoring";
      }

      # Web services
      {
        name = "homelab";
        type = "A";
        value = "192.168.100.100";
      }
      {
        name = "www";
        type = "CNAME";
        value = "homelab";
      }
    ];

    # Custom internal DNS zones
    customDnsZones = {
      "internal.local" = {
        ttl = 300;
        records = [
          { name = "gateway"; type = "A"; value = "192.168.1.1"; }
          { name = "switch"; type = "A"; value = "10.10.10.50"; }
          { name = "ap"; type = "A"; value = "10.10.10.51"; }
        ];
      };

      "k8s.local" = {
        records = [
          { name = "api"; type = "A"; value = "192.168.8.100"; }
          { name = "ingress"; type = "A"; value = "192.168.8.101"; }
          { name = "master-01"; type = "A"; value = "192.168.8.10"; }
          { name = "worker-01"; type = "A"; value = "192.168.8.11"; }
          { name = "worker-02"; type = "A"; value = "192.168.8.12"; }
        ];
      };
    };

    # VLAN configurations with per-VLAN static reservations
    vlans = [
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.100.0/24";
        router = "192.168.100.1";
        dhcpPool = "192.168.100.50 - 192.168.100.200";

        staticReservations = [
          {
            hostname = "workstation-1";
            mac = "11:11:11:11:11:11";
            ip = "192.168.100.10";
          }
          {
            hostname = "workstation-2";
            mac = "22:22:22:22:22:22";
            ip = "192.168.100.11";
          }
        ];
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.10.0/24";
        router = "192.168.10.1";

        staticReservations = [
          {
            hostname = "database-server";
            mac = "33:33:33:33:33:33";
            ip = "192.168.10.10";
          }
          {
            hostname = "web-server";
            mac = "44:44:44:44:44:44";
            ip = "192.168.10.11";
          }
          {
            hostname = "backup-server";
            mac = "55:55:55:55:55:55";
            ip = "192.168.10.12";
          }
        ];
      }
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.8.0/24";
        router = "192.168.8.1";

        staticReservations = [
          {
            hostname = "k8s-api";
            mac = "88:88:88:88:88:88";
            ip = "192.168.8.100";
          }
          {
            hostname = "k8s-master-01";
            mac = "89:89:89:89:89:89";
            ip = "192.168.8.10";
          }
        ];
      }
      {
        id = 99;
        name = "management";
        subnet = "10.50.99.0/24";
        router = "10.50.99.1";

        staticReservations = [
          {
            hostname = "monitoring";
            mac = "66:66:66:66:66:66";
            ip = "10.50.99.10";
          }
        ];
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.101.0/24";
        router = "192.168.101.1";
        # No static reservations for guest network
      }
    ];
  };

  networking.hostName = "router-example";
}
