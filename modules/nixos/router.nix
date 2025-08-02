{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.router;

  # Helper function to generate subnet configurations
  mkSubnet = { id, subnet, router, pool ? null }:
    let
      # Extract network part and calculate default pool range
      parts = splitString "." (head (splitString "/" subnet));
      network = concatStringsSep "." (take 3 parts);
      defaultPool = "${network}.20 - ${network}.240";
    in {
      inherit subnet id;
      pools = [ { pool = if pool != null then pool else defaultPool; } ];
      option-data = [
        { name = "routers"; data = router; }
      ];
    };  # Helper function to generate reverse DNS zone name
  mkReverseDnsZone = subnet:
    let
      parts = splitString "." (head (splitString "/" subnet));
      reverseParts = if (head parts) == "10" then
        # Handle 10.x.x.x networks
        [ (elemAt parts 2) (elemAt parts 1) (head parts) ]
      else
        # Handle 192.168.x.x networks
        [ (elemAt parts 2) (elemAt parts 1) (head parts) ];
    in "${concatStringsSep "." reverseParts}.in-addr.arpa.";

  # Generate DHCP subnets
  dhcpSubnets = map (vlan:
    mkSubnet {
      inherit (vlan) id subnet router;
      pool = vlan.dhcpPool or null;
    }
  ) cfg.vlans;  # Generate reverse DNS zones
  reverseDnsZones = listToAttrs (map (vlan: {
    name = mkReverseDnsZone vlan.subnet;
    value = {
      master = true;
      extraConfig = ''
        allow-update { key "dhcp-update-key"; };
        journal "db.${mkReverseDnsZone vlan.subnet}jnl";
        notify no;
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
  }) cfg.vlans);

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
      example = [ "192.168.14.0/24" "10.40.99.0/24" ];
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
          forwarders = [ "8.8.8.8" "1.1.1.1" ];
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

    customBindConfig = mkOption {
      type = types.str;
      default = "";
      description = "Additional BIND configuration";
    };
  };

  config = mkIf cfg.enable {
    # SOPS secrets configuration
    sops.secrets.cfApiToken = {
      sopsFile = ../../secrets/users.yaml;
    };
    sops.secrets."bind-ddns-tsig-file" = {
      sopsFile = ../../secrets/users.yaml;
      mode = "0644";
    };
    sops.secrets."ddns-tsig-key" = {
      sopsFile = ../../secrets/users.yaml;
      mode = "0644";
    };

    # Override the default router configuration
    networking.networkmanager.enable = lib.mkForce false;

    # Add router-specific packages
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
    systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
    systemd.services.NetworkManager-wait-online.enable = false;  # We don't use NetworkManager

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
    networking.interfaces = {
      ${cfg.wanInterface} = {
        useDHCP = true;
      };
    } // (optionalAttrs cfg.enableLan {
      ${cfg.lanInterface} = {
        ipv4.addresses = [{
          address = cfg.lanAddress;
          prefixLength = toInt (last (splitString "/" cfg.lanSubnet));
        }];
      };
    }) // (optionalAttrs cfg.enableOob {
      ${cfg.oobInterface} = {
        ipv4.addresses = [{
          address = cfg.oobAddress;
          prefixLength = toInt (last (splitString "/" cfg.oobSubnet));
        }];
      };
    }) // (listToAttrs (map (vlan: {
      name = "vlan${toString vlan.id}";
      value = {
        ipv4.addresses = [{
          address = vlan.router;
          prefixLength = toInt (last (splitString "/" vlan.subnet));
        }];
      };
    }) (filter (v: v.enabled) cfg.vlans)));

    # Configure NAT
    networking.nat = {
      enable = true;
      externalInterface = cfg.wanInterface;
      internalInterfaces = map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
    };    # Configure Tailscale
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

        interfaces-config = {
          interfaces = map (vlan: "vlan${toString vlan.id}/${vlan.router}") (filter (v: v.enabled) cfg.vlans)
            ++ optional cfg.enableOob "${cfg.oobInterface}/${cfg.oobAddress}"
            ++ optional cfg.enableLan "${cfg.lanInterface}/${cfg.lanAddress}";
        };

        option-data = [
          {
            name = "domain-name-servers";
            data = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
          }
          {
            name = "domain-search";
            data = "${cfg.domain},mole-bowfin.ts.net";
          }
        ] ++ cfg.customDhcpOptions;

        subnet4 = dhcpSubnets
          ++ optionals cfg.enableOob [
            {
              subnet = cfg.oobSubnet;
              id = 200;  # Use ID 200 for OOB to avoid conflicts with VLANs
              pools = [
                {
                  pool = let
                    parts = splitString "." cfg.oobAddress;
                    network = concatStringsSep "." (take 3 parts);
                  in "${network}.20 - ${network}.240";
                }
              ];
              option-data = [
                { name = "routers"; data = cfg.oobAddress; }
              ];
            }
          ]
          ++ optionals cfg.enableLan [
            {
              subnet = cfg.lanSubnet;
              id = 201;   # Use ID 201 for LAN
              pools = [
                {
                  pool = let
                    parts = splitString "." cfg.lanAddress;
                    network = concatStringsSep "." (take 3 parts);
                  in "${network}.20 - ${network}.240";
                }
              ];
              option-data = [
                { name = "routers"; data = cfg.lanAddress; }
              ];
            }
          ];
      };
    };

    # Configure DNS
    services.dnscrypt-proxy2 = {
      enable = true;
      settings = {
        listen_addresses = [ "127.0.0.1:53" ];
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
    ];

    services.bind = {
      enable = true;
      forward = "only";
      forwarders = [ "127.0.0.1" ];
      directory = "/var/lib/bind";
      listenOn = [
        (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router
      ];
      cacheNetworks = map (vlan: vlan.subnet) cfg.vlans ++ [
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
      '';

      extraConfig = ''
        include "${config.sops.secrets."bind-ddns-tsig-file".path}";
        # Tailscale
        zone "mole-bowfin.ts.net" {
            type forward;
            forwarders { 100.100.100.100; };
        };
        # Legacy zones
        zone "scr1.rabbito.tech" {
            type forward;
            forwarders { 10.5.0.7; 10.5.0.8; };
        };
        zone "kutara.io" {
            type forward;
            forwarders { 10.5.0.7; 10.5.0.8; };
        };
        ${concatStringsSep "\n" (mapAttrsToList (zone: config: ''
          zone "${zone}" {
              type forward;
              forwarders { ${concatStringsSep "; " config.forwarders}; };
          };
        '') cfg.forwardZones)}
        ${cfg.customBindConfig}
      '';

      zones = {
        "${cfg.domain}." = {
          master = true;
          extraConfig = ''
             allow-update { key "dhcp-update-key"; };
             journal "db.${cfg.domain}.jnl";
             notify no;
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
            unifi           IN    CNAME   unifi.scr1.rabbito.tech.
          '';
        };
      } // reverseDnsZones;
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
        "named.service"
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
              dns-servers = [{
                hostname = "";
                ip-address = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
                port = 53;
              }];
            }
          ];
        };
        reverse-ddns = {
          ddns-domains = map (vlan: {
            name = mkReverseDnsZone vlan.subnet;
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = (findFirst (v: v.id == 99) (head cfg.vlans) cfg.vlans).router;
              port = 53;
            }];
          }) cfg.vlans;
        };
      };
    };

    # Configure firewall
    networking.firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ] ++ map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
      interfaces = {
        ${cfg.wanInterface} = {
          allowedTCPPorts = [ 22 ];
          allowedUDPPorts = [ ];
        };
      };
    };

    # Configure additional services
    services.avahi = {
      enable = true;
      reflector = true;
      nssmdns4 = true;
      nssmdns6 = true;
    };

    services.miniupnpd = {
      enable = true;
      upnp = false;
      natpmp = true;
      externalInterface = cfg.wanInterface;
      internalIPs = map (vlan: "vlan${toString vlan.id}") (filter (v: v.enabled) cfg.vlans)
        ++ optional cfg.enableOob cfg.oobInterface
        ++ optional cfg.enableLan cfg.lanInterface;
    };
  };
}
