{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.services.router;

  # Helper function to generate subnet configurations
  mkSubnet = {
    id,
    subnet,
    router,
    pool ? null,
    staticReservations ? [],
  }: let
    # Extract network part and calculate default pool range
    parts = splitString "." (head (splitString "/" subnet));
    network = concatStringsSep "." (take 3 parts);
    defaultPool = "${network}.20 - ${network}.240";
  in {
    inherit subnet id;
    pools = [
      {
        pool =
          if pool != null
          then pool
          else defaultPool;
      }
    ];
    reservations =
      map (res: {
        hostname = res.hostname;
        hw-address = res.mac;
        ip-address = res.ip;
      })
      staticReservations;
    option-data = [
      {
        name = "routers";
        data = router;
      }
    ];
  };

  # Helper function to generate reverse DNS zone name
  mkReverseDnsZone = subnet: let
    parts = splitString "." (head (splitString "/" subnet));
    reverseParts =
      if (head parts) == "10"
      then
        # Handle 10.x.x.x networks
        [(elemAt parts 2) (elemAt parts 1) (head parts)]
      else
        # Handle 192.168.x.x networks
        [(elemAt parts 2) (elemAt parts 1) (head parts)];
  in "${concatStringsSep "." reverseParts}.in-addr.arpa.";

  # Helper helpers for working with zone file paths
  stripTrailingDot = zoneName:
    if hasSuffix "." zoneName
    then substring 0 (stringLength zoneName - 1) zoneName
    else zoneName;

  zoneFileName = zoneName: "db.${stripTrailingDot zoneName}";

  zoneFilePath = zoneName: "${config.services.bind.directory}/${zoneFileName zoneName}";

  zoneJournalPath = zoneName: "${zoneFilePath zoneName}.jnl";

  # Generate DHCP subnets
  dhcpSubnets =
    map (
      vlan:
        mkSubnet {
          inherit (vlan) id subnet router staticReservations;
          pool = vlan.dhcpPool or null;
        }
    )
    cfg.vlans;

  # Helper function to format DNS records for BIND zone file
  formatDnsRecord = record: let
    ttlPart =
      if record.ttl != null
      then "${toString record.ttl}"
      else "";
    priorityPart =
      if record.priority != null
      then "${toString record.priority} "
      else "";
    recordLine = "${record.name} ${ttlPart} IN ${record.type} ${priorityPart}${record.value}";
  in
    recordLine;

  # Generate DNS records text for zone file
  dnsRecordsText = concatStringsSep "\n" (map formatDnsRecord cfg.dnsRecords);

  mainZoneName = "${cfg.domain}.";
  mainZoneTemplateText = ''
    $ORIGIN ${cfg.domain}.
    $TTL    86400
    @ IN SOA ${cfg.domain}. admin.rabbito.tech (
    ${toString inputs.self.lastModified}           ; serial number
    3600                    ; refresh
    900                     ; retry
    1209600                 ; expire
    60                      ; ttl
    )
                        IN    NS      ${config.networking.hostName}.${cfg.domain}.
    ${config.networking.hostName}             IN    A       ${(findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router}
    ${optionalString (dnsRecordsText != "") "\n; Custom DNS records"}
    ${dnsRecordsText}
  '';

  mainZoneDefinition = {
    zoneName = mainZoneName;
    templatePath = pkgs.writeText (zoneFileName mainZoneName) mainZoneTemplateText;
    filePath = zoneFilePath mainZoneName;
    zoneAttr = {
      master = true;
      extraConfig = ''
        allow-update { key "dhcp-update-key"; };
        journal "${zoneJournalPath mainZoneName}";
        notify no;
        ixfr-from-differences yes;
        max-journal-size 1m;
      '';
      file = zoneFilePath mainZoneName;
    };
  };

  mkReverseDnsZoneDefinition = vlan: let
    zoneName = mkReverseDnsZone vlan.subnet;
    reverseZoneTemplate = pkgs.writeText (zoneFileName zoneName) ''
      $ORIGIN ${zoneName}
      $TTL    86400
      @ IN SOA ${cfg.domain}. admin.rabbito.tech (
      ${toString inputs.self.lastModified}           ; serial number
      3600                    ; refresh
      900                     ; retry
      1209600                 ; expire
      60                      ; ttl
      )
                      IN    NS      ${config.networking.hostName}.${cfg.domain}.
      ${optionalString (vlan.id == 99) "1               IN    PTR     ${config.networking.hostName}.${cfg.domain}."}
    '';
  in {
    zoneName = zoneName;
    templatePath = reverseZoneTemplate;
    filePath = zoneFilePath zoneName;
    zoneAttr = {
      master = true;
      extraConfig = ''
        allow-update { key "dhcp-update-key"; };
        journal "${zoneJournalPath zoneName}";
        notify no;
        ixfr-from-differences yes;
        max-journal-size 1m;
      '';
      file = zoneFilePath zoneName;
    };
  };

  reverseDnsZoneDefinitions = map mkReverseDnsZoneDefinition cfg.vlans;

  reverseDnsZones = listToAttrs (map (zone: {
      name = zone.zoneName;
      value = zone.zoneAttr;
    })
    reverseDnsZoneDefinitions);

  mkCustomZoneDefinition = zoneName: zoneConfig: let
    fqdn = "${zoneName}.";
    customZoneTemplate = pkgs.writeText (zoneFileName fqdn) ''
      $ORIGIN ${zoneName}.
      $TTL    ${toString zoneConfig.ttl}
      @ IN SOA ${zoneName}. ${zoneConfig.soaEmail} (
      ${toString inputs.self.lastModified}           ; serial number
      3600                    ; refresh
      900                     ; retry
      1209600                 ; expire
      60                      ; ttl
      )
                      IN    NS      ${config.networking.hostName}.${cfg.domain}.
      ${concatStringsSep "\n" (map formatDnsRecord zoneConfig.records)}
    '';
  in {
    zoneName = fqdn;
    templatePath = customZoneTemplate;
    filePath = zoneFilePath fqdn;
    zoneAttr = {
      master = true;
      extraConfig = ''
        allow-update { key "dhcp-update-key"; };
        journal "${zoneJournalPath fqdn}";
        notify no;
        ixfr-from-differences yes;
        max-journal-size 1m;
      '';
      file = zoneFilePath fqdn;
    };
  };

  customDnsZoneDefinitions = mapAttrsToList mkCustomZoneDefinition cfg.customDnsZones;

  # UniFi discovery DNS zone
  unifiDnsZone = optionals cfg.unifiDiscovery.enable [
    (mkCustomZoneDefinition "unifi" {
      records = [
        {
          name = "@";
          type = "A";
          value = cfg.unifiDiscovery.controllerAddress;
          ttl = null;
          priority = null;
        }
      ];
      soaEmail = "admin.rabbito.tech";
      ttl = 300;
    })
  ];

  customDnsZones = listToAttrs (map (zone: {
      name = zone.zoneName;
      value = zone.zoneAttr;
    })
    (customDnsZoneDefinitions ++ unifiDnsZone));

  zoneTemplateDefinitions =
    [mainZoneDefinition]
    ++ reverseDnsZoneDefinitions
    ++ customDnsZoneDefinitions
    ++ unifiDnsZone
    ++ optionals (cfg.rfc2136.enable) _rfc2136Config.externalDnsZoneDefinitions;

  zoneTmpfilesRules =
    map (
      zone: "C ${zone.filePath} 0644 named named - ${zone.templatePath}"
    )
    zoneTemplateDefinitions;

  # Helper variables for RFC 2136 / external-dns configuration
  _rfc2136Config = rec {
    # Always use the existing DHCP TSIG key for simplicity
    tsigKeyName = "dhcp-update-key";
    tsigSecretPath = config.sops.secrets."ddns-tsig-key".path;

    # Determine bind address - default to management VLAN router IP
    bindAddress =
      if cfg.rfc2136.bindAddress != ""
      then cfg.rfc2136.bindAddress
      else (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;

    # Filter out zones that are the same as the main domain - we'll handle those separately
    additionalExternalDnsZones = filter (zoneName: zoneName != cfg.domain) cfg.rfc2136.externalDnsZones;

    # Check if the main domain is included in external DNS zones
    mainDomainInExternalDns = elem cfg.domain cfg.rfc2136.externalDnsZones;

    # Generate external-dns zone configurations only for additional zones (not main domain)
    externalDnsZoneDefinitions =
      map (zoneName: let
        fqdn = "${zoneName}.";
        zoneTemplate = pkgs.writeText (zoneFileName fqdn) ''
          $ORIGIN ${zoneName}.
          $TTL    ${toString cfg.rfc2136.defaultTtl}
          @ IN SOA ${zoneName}. admin.rabbito.tech (
          ${toString inputs.self.lastModified}           ; serial number
          3600                    ; refresh
          900                     ; retry
          1209600                 ; expire
          60                                             ; minimum ttl
          )
                          IN    NS      ${config.networking.hostName}.${cfg.domain}.
          ; External-DNS managed records will be dynamically added here
        '';
      in {
        zoneName = fqdn;
        templatePath = zoneTemplate;
        filePath = zoneFilePath fqdn;
        zoneAttr = {
          master = true;
          slaves = ["key ${tsigKeyName}"];
          extraConfig = ''
            allow-update { key "${tsigKeyName}"; };
            journal "${zoneJournalPath fqdn}";
            notify no;
            ixfr-from-differences yes;
            max-journal-size 1m;
          '';
          file = zoneFilePath fqdn;
        };
      })
      additionalExternalDnsZones;

    externalDnsZones = listToAttrs (map (zone: {
        name = zone.zoneName;
        value = zone.zoneAttr;
      })
      externalDnsZoneDefinitions);
  };
in {
  options.services.router = {
    enable = mkEnableOption "Router Configuration";

    domain = mkOption {
      type = types.str;
      description = "The domain name for this network";
      example = "nwk3.rabbito.tech";
    };

    lanInterface = mkOption {
      type = types.str;
      default = "lan";
      description = "The LAN interface name";
    };

    wanInterface = mkOption {
      type = types.str;
      default = "wan";
      description = "The WAN interface name";
    };

    oobInterface = mkOption {
      type = types.str;
      default = "oob";
      description = "The Out-of-Band management interface name";
    };

    enableOob = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Out-of-Band management interface";
    };

    oobSubnet = mkOption {
      type = types.str;
      default = "10.10.10.0/24";
      description = "Out-of-Band management subnet";
    };

    oobAddress = mkOption {
      type = types.str;
      default = "10.10.10.1";
      description = "Out-of-Band management IP address";
    };

    oobStaticReservations = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "Hostname for the reservation";
          };

          mac = mkOption {
            type = types.str;
            description = "MAC address for the reservation";
          };

          ip = mkOption {
            type = types.str;
            description = "IP address for the reservation";
          };
        };
      });
      default = [];
      description = "Static DHCP reservations for the OOB network";
    };

    enableLan = mkOption {
      type = types.bool;
      default = true;
      description = "Enable LAN interface with IP assignment";
    };

    lanSubnet = mkOption {
      type = types.str;
      default = "192.168.1.0/24";
      description = "LAN subnet";
    };

    lanAddress = mkOption {
      type = types.str;
      default = "192.168.1.1";
      description = "LAN IP address";
    };

    lanStaticReservations = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "Hostname for the reservation";
          };

          mac = mkOption {
            type = types.str;
            description = "MAC address for the reservation";
          };

          ip = mkOption {
            type = types.str;
            description = "IP address for the reservation";
          };
        };
      });
      default = [];
      description = "Static DHCP reservations for the LAN network";
    };

    vlans = mkOption {
      type = types.listOf (types.submodule {
        options = {
          id = mkOption {
            type = types.int;
            description = "VLAN ID";
          };

          name = mkOption {
            type = types.str;
            description = "VLAN name/purpose";
          };

          subnet = mkOption {
            type = types.str;
            description = "Subnet in CIDR notation";
            example = "192.168.100.0/24";
          };

          router = mkOption {
            type = types.str;
            description = "Router IP address for this VLAN";
            example = "192.168.100.1";
          };

          dhcpPool = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Custom DHCP pool range";
            example = "192.168.100.50 - 192.168.100.200";
          };

          staticReservations = mkOption {
            type = types.listOf (types.submodule {
              options = {
                hostname = mkOption {
                  type = types.str;
                  description = "Hostname for the reservation";
                  example = "server1";
                };

                mac = mkOption {
                  type = types.str;
                  description = "MAC address for the reservation";
                  example = "aa:bb:cc:dd:ee:ff";
                };

                ip = mkOption {
                  type = types.str;
                  description = "IP address for the reservation";
                  example = "192.168.100.10";
                };
              };
            });
            default = [];
            description = "Static DHCP reservations for this VLAN";
            example = [
              {
                hostname = "server1";
                mac = "aa:bb:cc:dd:ee:ff";
                ip = "192.168.100.10";
              }
            ];
          };

          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this VLAN is enabled";
          };
        };
      });
      default = [];
      description = "VLAN configurations";
    };

    tailscaleRoutes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Additional routes to advertise via Tailscale";
      example = ["192.168.14.0/24" "10.40.99.0/24"];
    };

    cloudflaredomains = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Domains to update via Cloudflare DDNS";
    };

    forwardZones = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          forwarders = mkOption {
            type = types.listOf types.str;
            description = "DNS forwarders for this zone";
          };
        };
      });
      default = {};
      description = "Additional DNS forward zones";
      example = {
        "example.com" = {
          forwarders = ["8.8.8.8" "1.1.1.1"];
        };
      };
    };

    udevRules = mkOption {
      type = types.str;
      default = "";
      description = "Custom udev rules for interface naming";
    };

    customDhcpOptions = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Additional DHCP options";
    };

    globalStaticReservations = mkOption {
      type = types.listOf (types.submodule {
        options = {
          hostname = mkOption {
            type = types.str;
            description = "Hostname for the reservation";
            example = "server1";
          };

          mac = mkOption {
            type = types.str;
            description = "MAC address for the reservation";
            example = "aa:bb:cc:dd:ee:ff";
          };

          ip = mkOption {
            type = types.str;
            description = "IP address for the reservation";
            example = "192.168.100.10";
          };
        };
      });
      default = [];
      description = "Global static DHCP reservations (not tied to a specific VLAN)";
      example = [
        {
          hostname = "router";
          mac = "11:22:33:44:55:66";
          ip = "192.168.1.1";
        }
      ];
    };

    dnsRecords = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Record name (hostname)";
            example = "webserver";
          };

          type = mkOption {
            type = types.enum ["A" "AAAA" "CNAME" "MX" "TXT" "SRV" "PTR"];
            description = "DNS record type";
            example = "A";
          };

          value = mkOption {
            type = types.str;
            description = "Record value";
            example = "192.168.1.100";
          };

          ttl = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "TTL in seconds (optional, uses zone default if not specified)";
            example = 3600;
          };

          priority = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Priority for MX/SRV records";
            example = 10;
          };
        };
      });
      default = [];
      description = "Custom DNS records for the main domain zone";
      example = [
        {
          name = "webserver";
          type = "A";
          value = "192.168.1.100";
          ttl = 3600;
        }
        {
          name = "mail";
          type = "MX";
          value = "mail.example.com.";
          priority = 10;
        }
        {
          name = "www";
          type = "CNAME";
          value = "webserver";
        }
      ];
    };

    customDnsZones = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          records = mkOption {
            type = types.listOf (types.submodule {
              options = {
                name = mkOption {
                  type = types.str;
                  description = "Record name";
                };
                type = mkOption {
                  type = types.enum ["A" "AAAA" "CNAME" "MX" "TXT" "SRV" "PTR"];
                  description = "DNS record type";
                };
                value = mkOption {
                  type = types.str;
                  description = "Record value";
                };
                ttl = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                  description = "TTL in seconds";
                };
                priority = mkOption {
                  type = types.nullOr types.int;
                  default = null;
                  description = "Priority for MX/SRV records";
                };
              };
            });
            default = [];
            description = "DNS records for this zone";
          };

          soaEmail = mkOption {
            type = types.str;
            default = "admin.rabbito.tech";
            description = "SOA email address";
          };

          ttl = mkOption {
            type = types.int;
            default = 86400;
            description = "Default TTL for the zone";
          };
        };
      });
      default = {};
      description = "Custom DNS zones with their records";
      example = {
        "internal.local" = {
          records = [
            {
              name = "server1";
              type = "A";
              value = "10.0.0.10";
            }
            {
              name = "www";
              type = "CNAME";
              value = "server1";
            }
          ];
        };
      };
    };

    customBindConfig = mkOption {
      type = types.str;
      default = "";
      description = "Additional BIND configuration";
    };

    # RFC 2136 / external-dns configuration
    rfc2136 = {
      enable = mkEnableOption "RFC 2136 support for external-dns";

      externalDnsZones = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "DNS zones that external-dns should manage";
        example = ["qgr1.rabbito.tech" "kutara.io"];
      };

      bindAddress = mkOption {
        type = types.str;
        default = "";
        description = "IP address for external-dns to connect to BIND. Defaults to management VLAN router IP";
      };

      port = mkOption {
        type = types.int;
        default = 53;
        description = "Port for external-dns to connect to BIND";
      };

      defaultTtl = mkOption {
        type = types.int;
        default = 300;
        description = "Default TTL for external-dns managed records";
      };
    };

    # IPv6 configuration
    ipv6 = {
      enable = mkEnableOption "IPv6 support";

      enableRadvd = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Router Advertisement Daemon (radvd)";
      };

      radvdVlans = mkOption {
        type = types.listOf types.int;
        default = [100];
        description = "VLAN IDs on which to advertise IPv6 router advertisements with ULA prefixes";
        example = [99 100 200];
      };

      publicPrefixVlan = mkOption {
        type = types.nullOr types.int;
        default = 100;
        description = "VLAN ID that should receive the public/delegated IPv6 prefix from ISP. Only one VLAN can receive the delegated prefix.";
        example = 100;
      };

      upstreamPrefix = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "IPv6 prefix from upstream (auto-detected if null)";
        example = "2001:db8::/64";
      };

      enableDhcpv6Pd = mkOption {
        type = types.bool;
        default = true;
        description = "Enable DHCPv6 Prefix Delegation on WAN interface";
      };

      delegatedPrefixLength = mkOption {
        type = types.int;
        default = 56;
        description = "Length of delegated prefix to request (typically 56 or 60)";
      };
    };

    # Port forwarding configuration
    portForwarding = mkOption {
      type = types.listOf (types.submodule {
        options = {
          protocol = mkOption {
            type = types.enum ["tcp" "udp" "both"];
            description = "Protocol to forward (tcp, udp, or both)";
          };

          externalPort = mkOption {
            type = types.int;
            description = "External port to forward from";
          };

          internalIP = mkOption {
            type = types.str;
            description = "Internal IP address to forward to";
          };

          internalPort = mkOption {
            type = types.int;
            description = "Internal port to forward to";
          };

          description = mkOption {
            type = types.str;
            default = "";
            description = "Human-readable description of this port forward rule";
          };
        };
      });
      default = [];
      description = "List of port forwarding rules from WAN to internal hosts";
      example = [
        {
          protocol = "tcp";
          externalPort = 443;
          internalIP = "192.168.1.100";
          internalPort = 443;
          description = "HTTPS to web server";
        }
      ];
    };

    # UniFi Controller Discovery configuration
    unifiDiscovery = {
      enable = mkEnableOption "UniFi controller discovery via DNS";

      controllerAddress = mkOption {
        type = types.str;
        default = "";
        description = "IP address of the UniFi controller";
        example = "10.45.0.6";
      };
    };

    # Fail2ban configuration
    fail2ban = {
      enable = mkEnableOption "Fail2ban intrusion prevention";

      ignoreIP = mkOption {
        type = types.listOf types.str;
        default = [
          "127.0.0.0/8" # Localhost
          "10.0.0.0/8" # RFC 1918 - Private networks
          "172.16.0.0/12" # RFC 1918 - Private networks
          "192.168.0.0/16" # RFC 1918 - Private networks
          "169.254.0.0/16" # RFC 3927 - Link-local
          "::1/128" # IPv6 localhost
          "fc00::/7" # IPv6 unique local addresses
          "fe80::/10" # IPv6 link-local
        ];
        description = "List of IP addresses/networks to ignore (never ban)";
        example = [
          "127.0.0.0/8"
          "192.168.1.0/24"
          "10.0.0.0/8"
        ];
      };

      banTime = mkOption {
        type = types.str;
        default = "1h";
        description = "Default ban time for offending IPs";
        example = "24h";
      };

      findTime = mkOption {
        type = types.str;
        default = "10m";
        description = "Time window to count failures";
        example = "30m";
      };

      maxRetry = mkOption {
        type = types.int;
        default = 3;
        description = "Number of failures before banning";
        example = 5;
      };

      enabledJails = mkOption {
        type = types.listOf types.str;
        default = [
          "sshd"
          "router-scan"
          "router-dns-abuse"
        ];
        description = "List of jails to enable";
        example = [
          "sshd"
          "nginx-http-auth"
          "nginx-limit-req"
          "nginx-botsearch"
          "router-scan"
          "router-dhcp-abuse"
          "router-port-scan"
          "router-dns-abuse"
          "postfix"
          "dovecot"
        ];
      };

      customJails = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Custom jail configurations";
        example = {
          "custom-app" = ''
            enabled = true
            port = 8080
            logpath = /var/log/custom-app.log
            maxretry = 5
          '';
        };
      };

      whitelist = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional IP addresses/networks to whitelist beyond ignoreIP";
        example = [
          "203.0.113.0/24" # Trusted external network
          "198.51.100.5" # Specific trusted IP
        ];
      };

      banAction = mkOption {
        type = types.str;
        default = "iptables-multiport";
        description = "Default ban action to use";
        example = "iptables-allports";
      };

      logLevel = mkOption {
        type = types.enum ["CRITICAL" "ERROR" "WARNING" "NOTICE" "INFO" "DEBUG"];
        default = "INFO";
        description = "Fail2ban log level";
      };
    };
  };

  config = mkIf cfg.enable {
    sops.secrets.cfApiToken = {
      sopsFile = ../../secrets/users.yaml;
    };
    sops.secrets."bind-ddns-tsig-file" = {
      sopsFile = ../../secrets/users.yaml;
      mode = "0644";
    };
    sops.secrets."ddns-tsig-key" = {
      # TODO: poor secret name
      sopsFile = ../../secrets/users.yaml;
      mode = "0644";
    };

    # Override the default router configuration
    networking.networkmanager.enable = lib.mkForce false; # Add router-specific packages
    environment.systemPackages = with pkgs; [
      ethtool
      tcpdump
      conntrack-tools
      mtr
      nmap
    ];

    # Configure kernel parameters for routing
    boot.kernel.sysctl =
      {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
      }
      // (optionalAttrs cfg.ipv6.enable {
        # IPv6 configuration - disable RA and autoconf by default
        "net.ipv6.conf.all.accept_ra" = 0;
        "net.ipv6.conf.default.accept_ra" = 0;
        "net.ipv6.conf.all.autoconf" = 0;
        "net.ipv6.conf.default.autoconf" = 0;

        # WAN interface IPv6 settings - enable for upstream connectivity
        "net.ipv6.conf.${cfg.wanInterface}.accept_ra" = 2; # Accept RA even when forwarding
        "net.ipv6.conf.${cfg.wanInterface}.autoconf" = 1;
      });

    # Ensure network-online.target is enabled for proper dependency ordering
    systemd.targets.network-online.wantedBy = ["multi-user.target"];
    systemd.services.NetworkManager-wait-online.enable = false; # We don't use NetworkManager

    services.udev.extraRules = cfg.udevRules;

    # Configure VLANs
    networking.vlans = listToAttrs (map (vlan: {
      name = "vlan${toString vlan.id}";
      value = {
        id = vlan.id;
        interface = cfg.lanInterface;
      };
    }) (filter (v: v.enabled) cfg.vlans));

    # Configure VLAN interfaces
    networking.interfaces =
      {
        ${cfg.wanInterface} = {
          useDHCP = true;
          # IPv6 will be handled via sysctl settings, not interface options
        };
      }
      // (optionalAttrs cfg.enableLan {
        ${cfg.lanInterface} = {
          ipv4.addresses = [
            {
              address = cfg.lanAddress;
              prefixLength = toInt (last (splitString "/" cfg.lanSubnet));
            }
          ];
        };
      })
      // (optionalAttrs cfg.enableOob {
        ${cfg.oobInterface} = {
          ipv4.addresses = [
            {
              address = cfg.oobAddress;
              prefixLength = toInt (last (splitString "/" cfg.oobSubnet));
            }
          ];
        };
      })
      // (listToAttrs (map (vlan: {
        name = "vlan${toString vlan.id}";
        value =
          {
            ipv4.addresses = [
              {
                address = vlan.router;
                prefixLength = toInt (last (splitString "/" vlan.subnet));
              }
            ];
            # Add IPv6 addresses for management VLAN or radvd VLANs
          }
          // (optionalAttrs cfg.ipv6.enable {
            ipv6.addresses =
              if vlan.id == 99
              then [
                {
                  address = "fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:99::1";
                  prefixLength = 64;
                }
              ]
              else if elem vlan.id cfg.ipv6.radvdVlans
              then [
                {
                  address = "fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:${toString vlan.id}::1";
                  prefixLength = 64;
                }
              ]
              else [];
          });
      }) (filter (v: v.enabled) cfg.vlans)));

    # Configure NAT
    networking.nat = {
      enable = true;
      externalInterface = cfg.wanInterface;
      internalInterfaces =
        map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;

      # Exclude Tailscale CGNAT range from NAT - traffic to 100.64.0.0/10 should route via Tailscale
      # internalIPs = ["100.64.0.0/10"];
      # externalIP = "!100.64.0.0/10";

      # Port forwarding rules
      forwardPorts = flatten (map (rule:
        if rule.protocol == "both"
        then [
          {
            destination = "${rule.internalIP}:${toString rule.internalPort}";
            proto = "tcp";
            sourcePort = rule.externalPort;
          }
          {
            destination = "${rule.internalIP}:${toString rule.internalPort}";
            proto = "udp";
            sourcePort = rule.externalPort;
          }
        ]
        else [
          {
            destination = "${rule.internalIP}:${toString rule.internalPort}";
            proto = rule.protocol;
            sourcePort = rule.externalPort;
          }
        ])
      cfg.portForwarding);

      # Enable IPv6 forwarding if IPv6 is enabled
      enableIPv6 = cfg.ipv6.enable;
    };

    # Configure Router Advertisement Daemon (radvd) for IPv6
    services.radvd = mkIf (cfg.ipv6.enable && cfg.ipv6.enableRadvd) {
      enable = true;
      config = concatStringsSep "\n" (map (vlanId: let
        vlan = findFirst (v: v.id == vlanId) null (filter (v: v.enabled) cfg.vlans);
        isPublicVlan = cfg.ipv6.publicPrefixVlan == vlanId;
      in
        optionalString (vlan != null) ''
          interface vlan${toString vlanId} {
            AdvSendAdvert on;
            AdvManagedFlag off;
            AdvOtherConfigFlag on;
            AdvLinkMTU 1500;
            AdvCurHopLimit 64;
            AdvDefaultLifetime 9000;
            AdvReachableTime 0;
            AdvRetransTimer 0;

            # Use ULA prefix for internal networks (always advertised)
            prefix fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:${toString vlanId}::/64 {
              AdvOnLink on;
              AdvAutonomous on;
              AdvRouterAddr off;
              AdvPreferredLifetime 14400;
              AdvValidLifetime 86400;
            };

            ${optionalString isPublicVlan ''
            # Auto-advertise delegated prefix only on the designated public VLAN
            prefix ::/64 {
              AdvOnLink on;
              AdvAutonomous on;
              AdvRouterAddr off;
            };
          ''}

            # RDNSS for DNS - use management VLAN DNS server
            RDNSS fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:99::1 {
              AdvRDNSSLifetime 3600;
            };

            # DNS search domain
            DNSSL ${cfg.domain} {
              AdvDNSSLLifetime 3600;
            };
          };
        '')
      cfg.ipv6.radvdVlans);
    };

    # Configure DHCPv6 Prefix Delegation on WAN interface
    # Also ensure dhcpcd doesn't interfere with our static VLAN configuration
    networking.dhcpcd = mkMerge [
      {
        enable = true;
        # Only run on WAN interface - explicitly deny all other interfaces
        denyInterfaces =
          map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
          ++ optional cfg.enableOob cfg.oobInterface
          ++ optional cfg.enableLan cfg.lanInterface;
      }
      (mkIf (cfg.ipv6.enable && cfg.ipv6.enableDhcpv6Pd) {
        # When IPv6 PD is in use, restrict dhcpcd to WAN and provide IPv6-specific tuning
        allowInterfaces = [cfg.wanInterface];
        extraConfig = ''
          # Enable IPv6 Router Solicitation on WAN only
          interface ${cfg.wanInterface}
            ${optionalString (cfg.ipv6.publicPrefixVlan != null) "ia_pd ${toString cfg.ipv6.publicPrefixVlan}/::/64 vlan${toString cfg.ipv6.publicPrefixVlan}/0/64"}

          # Explicitly configure all other interfaces as static
          ${concatStringsSep "\n" (map (vlan: ''
            interface vlan${toString vlan.id}
              static ip_address=${vlan.router}/${toString (toInt (last (splitString "/" vlan.subnet)))}
              nohook resolv.conf
          '') (filter (v: v.enabled) cfg.vlans))}

          ${optionalString cfg.enableOob ''
            interface ${cfg.oobInterface}
              static ip_address=${cfg.oobAddress}/${toString (toInt (last (splitString "/" cfg.oobSubnet)))}
              nohook resolv.conf
          ''}

          ${optionalString cfg.enableLan ''
            interface ${cfg.lanInterface}
              static ip_address=${cfg.lanAddress}/${toString (toInt (last (splitString "/" cfg.lanSubnet)))}
              nohook resolv.conf
          ''}
        '';
      })
    ];
    # Configure Tailscale
    services.tailscale = {
      extraSetFlags =
        (optionals (cfg.tailscaleRoutes != []) [
          "--advertise-routes=${concatStringsSep "," cfg.tailscaleRoutes}"
        ])
        ++ [
          "--accept-routes"
          "--snat-subnet-routes=false"
        ];
      openFirewall = true;
      useRoutingFeatures = "both";
    };

    # Configure Kea Control Agent
    services.kea.ctrl-agent = {
      enable = true;
      settings = {
        http-host = "127.0.0.1";
        http-port = 8000;

        control-sockets = {
          dhcp4 = {
            socket-type = "unix";
            socket-name = "/run/kea/dhcp4-ctrl-socket";
          };
          dhcp6 = {
            socket-type = "unix";
            socket-name = "/run/kea/dhcp6-ctrl-socket";
          };
          d2 = {
            socket-type = "unix";
            socket-name = "/run/kea/dhcp-ddns-ctrl-socket";
          };
        };

        loggers = [
          {
            name = "kea-ctrl-agent";
            output_options = [
              {
                output = "stdout";
              }
            ];
            severity = "INFO";
          }
        ];
      };
    };

    # Configure DHCP
    services.kea.dhcp4 = {
      enable = true;
      settings = {
        dhcp-ddns.enable-updates = true;
        ddns-replace-client-name = "when-not-present";
        ddns-update-on-renew = true;
        ddns-override-client-update = true;
        ddns-override-no-update = true;
        ddns-qualifying-suffix = cfg.domain;
        lease-database = {
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
          type = "memfile";
        };
        rebind-timer = 2000;
        renew-timer = 1000;
        valid-lifetime = 4000;

        # Global static reservations
        reservations =
          map (res: {
            hostname = res.hostname;
            hw-address = res.mac;
            ip-address = res.ip;
          })
          cfg.globalStaticReservations;

        interfaces-config = {
          interfaces =
            map (vlan: "vlan${toString vlan.id}/${vlan.router}") (filter (v: v.enabled) cfg.vlans)
            ++ optional cfg.enableOob "${cfg.oobInterface}/${cfg.oobAddress}"
            ++ optional cfg.enableLan "${cfg.lanInterface}/${cfg.lanAddress}";
        };

        option-data =
          [
            {
              name = "domain-name-servers";
              data = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
            }
            {
              name = "domain-search";
              data = "${cfg.domain},mole-bowfin.ts.net";
            }
          ]
          ++ cfg.customDhcpOptions;

        subnet4 =
          dhcpSubnets
          ++ optionals cfg.enableOob [
            {
              subnet = cfg.oobSubnet;
              id = 200; # Use ID 200 for OOB to avoid conflicts with VLANs
              pools = [
                {
                  pool = let
                    parts = splitString "." cfg.oobAddress;
                    network = concatStringsSep "." (take 3 parts);
                  in "${network}.20 - ${network}.240";
                }
              ];
              reservations =
                map (res: {
                  hostname = res.hostname;
                  hw-address = res.mac;
                  ip-address = res.ip;
                })
                cfg.oobStaticReservations;
              option-data = [
                {
                  name = "routers";
                  data = cfg.oobAddress;
                }
              ];
            }
          ]
          ++ optionals cfg.enableLan [
            {
              subnet = cfg.lanSubnet;
              id = 201; # Use ID 201 for LAN
              pools = [
                {
                  pool = let
                    parts = splitString "." cfg.lanAddress;
                    network = concatStringsSep "." (take 3 parts);
                  in "${network}.20 - ${network}.240";
                }
              ];
              reservations =
                map (res: {
                  hostname = res.hostname;
                  hw-address = res.mac;
                  ip-address = res.ip;
                })
                cfg.lanStaticReservations;
              option-data = [
                {
                  name = "routers";
                  data = cfg.lanAddress;
                }
              ];
            }
          ];
      };
    };

    # Configure DNS
    services.dnscrypt-proxy = {
      enable = true;
      settings = {
        listen_addresses = ["127.0.0.1:53"];
        allowed_names = {
          allowed_names_file = pkgs.writeText "allow_list.txt" ''
            # Rabbit Cloud
            firebaselogging.googleapis.com
          '';
        };
      };
    };

    systemd.tmpfiles.rules =
      [
        "d /var/lib/bind 0775 named named -"
        "Z /var/lib/bind 0775 named named -"
        "f /var/log/bind-maintenance.log 0644 named named -"
      ]
      ++ zoneTmpfilesRules;

    # Create configuration files for auxiliary services
    environment.etc = {
      "fail2ban/filter.d/router-scan.conf" = mkIf cfg.fail2ban.enable {
        text = ''
          # Fail2Ban filter for router SSH scanning attempts
          [INCLUDES]
          before = common.conf

          [Definition]
          _daemon = sshd
          failregex = ^%(__prefix_line)s(?:error: PAM: )?[aA]uthentication (?:failure|error|failed) for .* from <HOST>( via \S+)?\s*$
                      ^%(__prefix_line)s(?:error: )?Received disconnect from <HOST>: 3: .*: Auth fail$
                      ^%(__prefix_line)sFailed \S+ for .*? from <HOST>(?: port \d*)?(?: ssh\d*)?$
                      ^%(__prefix_line)sROOT LOGIN REFUSED.* FROM <HOST>$
                      ^%(__prefix_line)s[iI](?:llegal|nvalid) user .* from <HOST>$
                      ^%(__prefix_line)sUser .+ from <HOST> not allowed because not listed in AllowUsers$
                      ^%(__prefix_line)sConnection closed by <HOST> port \d+ \[preauth\]$

          ignoreregex =

          # DEV Notes:
          # Enhanced SSH filter for router-specific scanning patterns
          # Uses standard fail2ban common.conf for prefix handling
        '';
        mode = "0644";
      };

      "fail2ban/filter.d/router-dhcp-abuse.conf" = mkIf cfg.fail2ban.enable {
        text = ''
          # Fail2Ban filter for DHCP abuse attempts
          [INCLUDES]
          before = common.conf

          [Definition]
          _daemon = dhcp
          failregex = ^%(__prefix_line)sDHCPDISCOVER from [0-9a-f:]+ \(<HOST>\) via.*$
                      ^%(__prefix_line)sDHCPREQUEST for .* from [0-9a-f:]+ \(<HOST>\) via.*$
                      ^%(__prefix_line)sDHCP packet from <HOST> discarded.*$
                      ^%(__prefix_line)sExcessive DHCP requests from <HOST>.*$
                      ^%(__prefix_line)sclient <HOST> sends too many requests.*$

          ignoreregex =

          # DEV Notes:
          # Detects DHCP flooding and abuse patterns
          # Note: May need adjustment based on actual Kea DHCP log format
        '';
        mode = "0644";
      };

      "fail2ban/filter.d/router-port-scan.conf" = mkIf cfg.fail2ban.enable {
        text = ''
          # Fail2Ban filter for port scanning attempts
          [INCLUDES]
          before = common.conf

          [Definition]
          _daemon = kernel
          failregex = ^%(__prefix_line)s.*IN=.* SRC=<HOST>.*DPT=\d+.*$
                      ^%(__prefix_line)s.*\[UFW BLOCK\] IN=.* SRC=<HOST>.*$
                      ^%(__prefix_line)s.*DROP.*SRC=<HOST>.*DPT=\d+.*$
                      ^%(__prefix_line)s.*nf_conntrack:.*SRC=<HOST>.*$

          ignoreregex =

          # DEV Notes:
          # Detects port scanning via kernel/firewall logs
          # Adjust patterns based on actual firewall logging
        '';
        mode = "0644";
      };

      "fail2ban/filter.d/router-dns-abuse.conf" = mkIf cfg.fail2ban.enable {
        text = ''
          # Fail2Ban filter for DNS abuse attempts
          [INCLUDES]
          before = common.conf

          [Definition]
          _daemon = named
          failregex = ^%(__prefix_line)sclient <HOST>#\d+.*query \(cache\) .*/IN denied$
                      ^%(__prefix_line)sclient <HOST>#\d+.*too many queries$
                      ^%(__prefix_line)sclient <HOST>#\d+.*query denied$
                      ^%(__prefix_line)sclient <HOST>#\d+.*rate limit exceeded$
                      ^%(__prefix_line)sclient <HOST>#\d+.*FORMERR.*$

          ignoreregex =

          # DEV Notes:
          # Detects DNS abuse patterns and query flooding
          # Based on BIND9 named log format
        '';
        mode = "0644";
      };

      "fail2ban/filter.d/router-web-scan.conf" = mkIf cfg.fail2ban.enable {
        text = ''
          # Fail2Ban filter for web scanning attempts on router interfaces
          [INCLUDES]
          before = common.conf

          [Definition]
          _daemon = nginx
          failregex = ^<HOST> -.*"(GET|POST|HEAD) .*(\.php|\.asp|\.cgi|admin|login|wp-admin|phpmyadmin).*" (404|403|401).*$
                      ^<HOST> -.*"(GET|POST) .*/\.\./.*" .*$
                      ^<HOST> -.*"(GET|POST) .*/(etc/passwd|proc/|dev/).*" .*$
                      ^<HOST> -.*"(GET|POST) .*(cmd=|exec=|union.*select).*" .*$
                      ^<HOST> -.*".*(/\?|\.\.\\).*" (400|404|403).*$

          ignoreregex =

          # DEV Notes:
          # Detects web application scanning and exploit attempts
          # Common patterns for admin panel discovery and path traversal
        '';
        mode = "0644";
      };
    };

    # Configure router-specific fail2ban jails using services.fail2ban.jails
    services.fail2ban = mkIf cfg.fail2ban.enable {
      enable = true;

      # Combine default ignoreIP with user-specified whitelist and dynamic VLAN subnets
      ignoreIP =
        cfg.fail2ban.ignoreIP
        ++ cfg.fail2ban.whitelist
        ++ (map (vlan: vlan.subnet) cfg.vlans)
        ++ (optional cfg.enableLan cfg.lanSubnet)
        ++ (optional cfg.enableOob cfg.oobSubnet);

      bantime = cfg.fail2ban.banTime;
      maxretry = cfg.fail2ban.maxRetry;
      banaction = cfg.fail2ban.banAction;
      banaction-allports = "${cfg.fail2ban.banAction}-allports";

      bantime-increment = {
        enable = true;
        formula = "ban.Time * (1<<(ban.Count if ban.Count<20 else 20)) * banFactor";
        factor = "2";
        maxtime = "72h";
      };

      jails = {
        # Router SSH scanning attempts
        router-scan = {
          settings = {
            enabled = true;
            filter = "router-scan";
            logpath = "/var/log/auth.log";
            maxretry = 3;
            bantime = cfg.fail2ban.banTime;
          };
        };

        # DHCP abuse attempts
        router-dhcp-abuse = {
          settings = {
            enabled = true;
            filter = "router-dhcp-abuse";
            logpath = "/var/log/kea-dhcp4.log";
            maxretry = 5;
            bantime = cfg.fail2ban.banTime;
          };
        };

        # Port scanning attempts
        router-port-scan = {
          settings = {
            enabled = true;
            filter = "router-port-scan";
            logpath = "/var/log/kern.log";
            maxretry = 10;
            bantime = cfg.fail2ban.banTime;
          };
        };

        # DNS abuse attempts
        router-dns-abuse = {
          settings = {
            enabled = true;
            filter = "router-dns-abuse";
            logpath = "/var/log/named/security.log";
            maxretry = 5;
            bantime = cfg.fail2ban.banTime;
          };
        };

        # Web scanning attempts on router interfaces
        router-web-scan = {
          settings = {
            enabled = true;
            filter = "router-web-scan";
            logpath = "/var/log/nginx/access.log";
            maxretry = 3;
            bantime = cfg.fail2ban.banTime;
          };
        };
      };
    };

    # Service to clean BIND journal files on startup to prevent DDNS corruption
    systemd.services.bind-journal-cleanup = {
      description = "Clean BIND journal files to prevent DDNS corruption";
      before = ["bind.service"];
      wantedBy = ["bind.service"];
      serviceConfig = {
        Type = "oneshot";
        User = "named";
        Group = "named";
        ExecStart = pkgs.writeShellScript "clean-bind-journals" ''
          # Remove all journal files to prevent corruption issues
          find /var/lib/bind -name "*.jnl" -delete
          # Remove any backup zone files that might cause conflicts
          find /var/lib/bind -name "*.bak" -delete
        '';
      };
    };

    # Timer to periodically clean up BIND journals (weekly)
    systemd.timers.bind-journal-maintenance = {
      description = "Periodic BIND journal maintenance";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    systemd.services.bind-journal-maintenance = {
      description = "Periodic BIND journal maintenance";
      serviceConfig = {
        Type = "oneshot";
        User = "named";
        Group = "named";
        ExecStart = pkgs.writeShellScript "maintain-bind-journals" ''
          set -euo pipefail

          # Check if BIND is running before attempting maintenance
          if ! systemctl is-active --quiet bind.service; then
            echo "$(date): BIND is not running, skipping maintenance" >> /var/log/bind-maintenance.log
            exit 0
          fi

          # Compact journal files by forcing zone sync
          if ${pkgs.bind}/bin/rndc sync -clean 2>/dev/null; then
            echo "$(date): Successfully synced zones" >> /var/log/bind-maintenance.log
          else
            echo "$(date): Warning: rndc sync failed, continuing with cleanup" >> /var/log/bind-maintenance.log
          fi

          # Remove old journal files larger than 1MB (they should be smaller due to max-journal-size)
          DELETED=$(find /var/lib/bind -name "*.jnl" -size +1M -delete -print | wc -l)
          if [ "$DELETED" -gt 0 ]; then
            echo "$(date): Removed $DELETED oversized journal files" >> /var/log/bind-maintenance.log
          fi

          # Log maintenance activity
          echo "$(date): BIND journal maintenance completed successfully" >> /var/log/bind-maintenance.log
        '';
        # Add some additional safeguards
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = ["/var/lib/bind" "/var/log"];
        NoNewPrivileges = true;
      };
      after = ["bind.service"];
      requisite = ["bind.service"]; # More strict than requires - won't start if bind isn't running
    };

    services.bind = {
      enable = true;
      forward = "only";
      forwarders = ["127.0.0.1"];
      directory = "/var/lib/bind";
      listenOn = [
        (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router
      ];
      # Listen on IPv6 address on management VLAN when IPv6 is enabled
      listenOnIpv6 = mkIf cfg.ipv6.enable [
        "fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:99::1"
      ];
      cacheNetworks =
        map (vlan: vlan.subnet) cfg.vlans
        ++ [
          # Tailscale
          "100.64.0.0/10"
        ]
        # Add IPv6 ULA networks when IPv6 is enabled
        ++ (optionals cfg.ipv6.enable (
          map (vlanId: "fd${substring 0 2 (builtins.hashString "sha256" cfg.domain)}:${substring 2 4 (builtins.hashString "sha256" cfg.domain)}:${toString vlanId}::/64") cfg.ipv6.radvdVlans
        ));
      extraOptions = ''
        dnssec-validation no;
        notify no;
        dump-file "/var/lib/bind/cache_dump.db";
        statistics-file "/var/lib/bind/named_stats.txt";
        memstatistics-file "/var/lib/bind/named_mem_stats.txt";

        # Journal and zone transfer settings to prevent corruption
        max-journal-size 1m;
        ixfr-from-differences yes;

        # Improved error handling for DDNS
        request-expire yes;
        serial-query-rate 20;
      '';

      extraConfig = ''
        include "${config.sops.secrets."bind-ddns-tsig-file".path}";

        ${optionalString (config.services.observability.exporters.bind or false) ''
          # Statistics endpoint for prometheus bind-exporter
          statistics-channels {
            inet 127.0.0.1 port 8053 allow { 127.0.0.1; };
          };
        ''}

        # Tailscale
        zone "mole-bowfin.ts.net" {
            type forward;
            forwarders { 100.100.100.100; };
        };
        ${concatStringsSep "\n" (mapAttrsToList (zone: config: ''
            zone "${zone}" {
                type forward;
                forwarders { ${concatStringsSep "; " config.forwarders}; };
            };
          '')
          cfg.forwardZones)}
        ${cfg.customBindConfig}
      '';

      zones =
        {
          "${cfg.domain}." = mainZoneDefinition.zoneAttr;
        }
        // reverseDnsZones
        // customDnsZones
        // (optionalAttrs cfg.rfc2136.enable _rfc2136Config.externalDnsZones);
    };

    # Configure DDNS
    services.cloudflare-dyndns = {
      enable = true;
      apiTokenFile = config.sops.secrets.cfApiToken.path;
      domains = cfg.cloudflaredomains;
      ipv6 = cfg.ipv6.enable;
    };

    # Ensure cloudflare-dyndns waits for network and DNS to be ready
    systemd.services.cloudflare-dyndns = {
      after = [
        "network-online.target"
        "dnscrypt-proxy.service"
        "bind.service"
        "systemd-resolved.service"
      ];
      wants = [
        "network-online.target"
      ];
      # Add a delay to ensure services are fully ready
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 30";
      };
    };

    services.kea.dhcp-ddns = {
      enable = true;
      settings = {
        # Improved logging and error handling
        loggers = [
          {
            name = "kea-dhcp-ddns.d2-to-dns";
            output_options = [
              {
                output = "stdout";
                maxver = 10;
                maxsize = 1048576;
              }
            ];
            severity = "INFO";
            debuglevel = 0;
          }
        ];

        # DNS update retry settings
        dns-server-timeout = 1000; # 1 second timeout
        ncr-protocol = "UDP";
        ncr-format = "JSON";

        tsig-keys = [
          {
            name = "dhcp-update-key";
            algorithm = "hmac-sha256";
            secret-file = config.sops.secrets."ddns-tsig-key".path;
          }
        ];
        forward-ddns = {
          ddns-domains = [
            {
              name = "${cfg.domain}.";
              key-name = "dhcp-update-key";
              dns-servers = [
                {
                  hostname = "";
                  ip-address = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
                  port = 53;
                }
              ];
            }
          ];
        };
        reverse-ddns = {
          ddns-domains =
            map (vlan: {
              name = mkReverseDnsZone vlan.subnet;
              key-name = "dhcp-update-key";
              dns-servers = [
                {
                  hostname = "";
                  ip-address = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
                  port = 53;
                }
              ];
            })
            cfg.vlans;
        };
      };
    };

    # Ensure kea-dhcp-ddns waits for BIND to be ready and journals cleaned
    systemd.services.kea-dhcp-ddns = {
      after = [
        "bind.service"
        "bind-journal-cleanup.service"
        "network-online.target"
      ];
      wants = [
        "bind.service"
        "network-online.target"
      ];
      serviceConfig = {
        # Add a small delay to ensure BIND is fully ready
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        # Restart on failure to recover from DNS issues
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    # Configure firewall
    networking.firewall = {
      enable = true;
      trustedInterfaces =
        ["tailscale0"]
        ++ map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
      interfaces = {
        ${cfg.wanInterface} = {
          allowedTCPPorts =
            [22]
            ++ (unique (map (rule: rule.externalPort) (filter (rule: rule.protocol == "tcp" || rule.protocol == "both") cfg.portForwarding)));
          allowedUDPPorts = unique (map (rule: rule.externalPort) (filter (rule: rule.protocol == "udp" || rule.protocol == "both") cfg.portForwarding));
        };
      };

      extraCommands = ''
        iptables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        iptables -t mangle -I FORWARD -o tailscale0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        iptables -t mangle -I FORWARD -i tailscale0 -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

        # SNAT LAN traffic going to Tailscale for cross-site routing
        ${optionalString cfg.enableLan ''
          iptables -t nat -A POSTROUTING -s ${cfg.lanSubnet} -o tailscale0 -j MASQUERADE
        ''}
      '';
    };

    # Configure additional services
    services.avahi = {
      enable = true;
      reflector = true;
      nssmdns4 = true;
      nssmdns6 = true;
      ipv4 = true;
      ipv6 = cfg.ipv6.enable;
      publish.enable = true;
      publish.addresses = true;
      publish.workstation = false;
      allowInterfaces =
        map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
    };

    services.miniupnpd = {
      enable = true;
      upnp = false;
      natpmp = true;
      externalInterface = cfg.wanInterface;
      internalIPs =
        map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
    };

    # Ensure miniupnpd waits for network interfaces and NAT to be ready
    systemd.services.miniupnpd = {
      after = [
        "network-online.target"
        "firewall.service"
        "systemd-networkd.service"
      ];
      wants = [
        "network-online.target"
      ];
      # Add a delay to ensure all interfaces and NAT rules are ready
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 15";
      };
    };

    # Router-specific observability configuration
    # Enable exporters and advanced log parsing when observability is enabled
    services.observability = mkIf (config.services.observability.enable or false) {
      exporters = {
        # Always enable node exporter for routers
        node = mkForce true;

        # Enable BIND exporter if DNS is configured
        bind = mkForce (cfg.vlans != []);

        # Enable FRR exporter if BGP is configured
        frr = mkForce (config.services.bgp.enable or false);
      };

      # Add router-specific Vector configuration for log parsing
      vector.extraLabels = mkDefault {
        role = "router";
        domain = cfg.domain;
      };
    };
  };
}
