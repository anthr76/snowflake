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
    reservations = map (res: {
      hostname = res.hostname;
      hw-address = res.mac;
      ip-address = res.ip;
    }) staticReservations;
    option-data = [
      {
        name = "routers";
        data = router;
      }
    ];
  }; # Helper function to generate reverse DNS zone name
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

  # Generate DHCP subnets
  dhcpSubnets =
    map (
      vlan:
        mkSubnet {
          inherit (vlan) id subnet router staticReservations;
          pool = vlan.dhcpPool or null;
        }
    )
    cfg.vlans; # Generate reverse DNS zones
  reverseDnsZones = listToAttrs (map (vlan: {
      name = mkReverseDnsZone vlan.subnet;
      value = {
        master = true;
        extraConfig = ''
          allow-update { key "dhcp-update-key"; };
          journal "db.${mkReverseDnsZone vlan.subnet}jnl";
          notify no;
          ixfr-from-differences yes;
          max-journal-size 1m;
        '';
        file = pkgs.writeText (mkReverseDnsZone vlan.subnet) ''
          $ORIGIN ${mkReverseDnsZone vlan.subnet}
          $TTL    86400
          @ IN SOA ${cfg.domain}. admin.rabbito.tech (
          ${toString inputs.self.lastModified}           ; serial number
          3600                    ; refresh
          900                     ; retry
          1209600                 ; expire
          1800                    ; ttl
          )
                          IN    NS      ${config.networking.hostName}.${cfg.domain}.
          ${optionalString (vlan.id == 99) "1               IN    PTR     ${config.networking.hostName}.${cfg.domain}."}
        '';
      };
    })
    cfg.vlans);

  # Helper function to format DNS records for BIND zone file
  formatDnsRecord = record: let
    ttlPart = if record.ttl != null then "${toString record.ttl}" else "";
    priorityPart = if record.priority != null then "${toString record.priority} " else "";
    recordLine = "${record.name} ${ttlPart} IN ${record.type} ${priorityPart}${record.value}";
  in recordLine;

  # Generate DNS records text for zone file
  dnsRecordsText = concatStringsSep "\n" (map formatDnsRecord cfg.dnsRecords);

  # Helper function to generate custom DNS zones
  mkCustomZone = zoneName: zoneConfig: {
    name = "${zoneName}.";
    value = {
      master = true;
      extraConfig = ''
        allow-update { key "dhcp-update-key"; };
        journal "db.${zoneName}.jnl";
        notify no;
        ixfr-from-differences yes;
        max-journal-size 1m;
      '';
      file = pkgs.writeText zoneName ''
        $ORIGIN ${zoneName}.
        $TTL    ${toString zoneConfig.ttl}
        @ IN SOA ${zoneName}. ${zoneConfig.soaEmail} (
        ${toString inputs.self.lastModified}           ; serial number
        3600                    ; refresh
        900                     ; retry
        1209600                 ; expire
        1800                    ; ttl
        )
                        IN    NS      ${config.networking.hostName}.${cfg.domain}.
        ${concatStringsSep "\n" (map formatDnsRecord zoneConfig.records)}
      '';
    };
  };

  # Generate custom DNS zones
  customDnsZones = listToAttrs (mapAttrsToList mkCustomZone cfg.customDnsZones);

  # Helper variables for RFC 2136 / external-dns configuration
  _rfc2136Config = rec {
    # Always use the existing DHCP TSIG key for simplicity
    tsigKeyName = "dhcp-update-key";
    tsigSecretPath = config.sops.secrets."ddns-tsig-key".path;

    # Determine bind address - default to management VLAN router IP
    bindAddress = if cfg.rfc2136.bindAddress != ""
      then cfg.rfc2136.bindAddress
      else (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;

    # Filter out zones that are the same as the main domain - we'll handle those separately
    additionalExternalDnsZones = filter (zoneName: zoneName != cfg.domain) cfg.rfc2136.externalDnsZones;

    # Check if the main domain is included in external DNS zones
    mainDomainInExternalDns = elem cfg.domain cfg.rfc2136.externalDnsZones;

    # Generate external-dns zone configurations only for additional zones (not main domain)
    externalDnsZones = listToAttrs (map (zoneName: {
      name = "${zoneName}.";
      value = {
        master = true;
        slaves = ["key ${tsigKeyName}"];
        extraConfig = ''
          allow-update { key "${tsigKeyName}"; };
          journal "db.${zoneName}.jnl";
          notify no;
          ixfr-from-differences yes;
          max-journal-size 1m;
        '';
        file = pkgs.writeText "${zoneName}.zone" ''
          $ORIGIN ${zoneName}.
          $TTL    ${toString cfg.rfc2136.defaultTtl}
          @ IN SOA ${zoneName}. admin.rabbito.tech (
          ${toString inputs.self.lastModified}           ; serial number
          3600                    ; refresh
          900                     ; retry
          1209600                 ; expire
          ${toString cfg.rfc2136.defaultTtl}             ; minimum ttl
          )
                          IN    NS      ${config.networking.hostName}.${cfg.domain}.
          ; External-DNS managed records will be dynamically added here
        '';
      };
    }) additionalExternalDnsZones);
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
            { name = "server1"; type = "A"; value = "10.0.0.10"; }
            { name = "www"; type = "CNAME"; value = "server1"; }
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
        example = ["scr1.rabbito.tech" "kutara.io"];
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
    networking.networkmanager.enable = lib.mkForce false;    # Add router-specific packages
    environment.systemPackages = with pkgs; [
      ethtool
      tcpdump
      conntrack-tools
      mtr
      nmap
    ];

    # Configure kernel parameters for routing
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = true;
      "net.ipv6.conf.all.forwarding" = true;
      "net.ipv6.conf.wan.disable_ipv6" = true;
    };

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
        value = {
          ipv4.addresses = [
            {
              address = vlan.router;
              prefixLength = toInt (last (splitString "/" vlan.subnet));
            }
          ];
        };
      }) (filter (v: v.enabled) cfg.vlans)));

    # Configure NAT
    networking.nat = {
      enable = true;
      externalInterface = cfg.wanInterface;
      internalInterfaces =
        map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
    }; # Configure Tailscale
    services.tailscale.extraUpFlags = mkIf (cfg.tailscaleRoutes != []) [
      "--advertise-routes=${concatStringsSep "," cfg.tailscaleRoutes}"
    ];

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
        reservations = map (res: {
          hostname = res.hostname;
          hw-address = res.mac;
          ip-address = res.ip;
        }) cfg.globalStaticReservations;

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
              reservations = map (res: {
                hostname = res.hostname;
                hw-address = res.mac;
                ip-address = res.ip;
              }) cfg.oobStaticReservations;
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
              reservations = map (res: {
                hostname = res.hostname;
                hw-address = res.mac;
                ip-address = res.ip;
              }) cfg.lanStaticReservations;
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
    services.dnscrypt-proxy2 = {
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

    systemd.tmpfiles.rules = [
      "d /var/lib/bind 0775 named named -"
      "Z /var/lib/bind 0775 named named -"
      "f /var/log/bind-maintenance.log 0644 named named -"
    ];

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
      cacheNetworks =
        map (vlan: vlan.subnet) cfg.vlans
        ++ [
          # Additional networks that may need caching
          "192.168.12.0/24"
          "192.168.6.0/24"
          "192.168.4.0/24"
          "10.20.99.0/24"
          "10.5.0.0/24"
        ];
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
        # Tailscale
        zone "mole-bowfin.ts.net" {
            type forward;
            forwarders { 100.100.100.100; };
        };
        # Legacy zones
        # zone "kutara.io" {
        #     type forward;
        #     forwarders { 10.5.0.7; 10.5.0.8; };
        # };
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
          "${cfg.domain}." = ({
            master = true;
            extraConfig = ''
              allow-update { key "dhcp-update-key"; };
              journal "db.${cfg.domain}.jnl";
              notify no;
              ixfr-from-differences yes;
              max-journal-size 1m;
            '';
            file = pkgs.writeText cfg.domain ''
              $ORIGIN ${cfg.domain}.
              $TTL    86400
              @ IN SOA ${cfg.domain}. admin.rabbito.tech (
              ${toString inputs.self.lastModified}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      ${config.networking.hostName}.${cfg.domain}.
              ${config.networking.hostName}             IN    A       ${(findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router}
              ${optionalString (dnsRecordsText != "") "\n; Custom DNS records"}
              ${dnsRecordsText}
            '';
          } // (optionalAttrs (cfg.rfc2136.enable && _rfc2136Config.mainDomainInExternalDns) {
            slaves = ["key ${_rfc2136Config.tsigKeyName}"];
          }));
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
    };

    # Ensure cloudflare-dyndns waits for network and DNS to be ready
    systemd.services.cloudflare-dyndns = {
      after = [
        "network-online.target"
        "dnscrypt-proxy2.service"
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
          allowedTCPPorts = [22];
          allowedUDPPorts = [];
        };
      };
    };

    # Configure additional services
    services.avahi = {
      enable = true;
      reflector = true;
      nssmdns4 = true;
      nssmdns6 = true;
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
  };
}
