{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.bgp;
in {
  options.services.bgp = {
    enable = mkEnableOption "BGP daemon for MetalLB support";

    routerId = mkOption {
      type = types.str;
      description = "BGP router ID (usually the router's main IP)";
      example = "192.168.1.1";
    };

    localASN = mkOption {
      type = types.int;
      description = "Local AS number";
      default = 64512;
    };

    peers = mkOption {
      type = types.listOf (types.submodule {
        options = {
          address = mkOption {
            type = types.str;
            description = "Peer IP address";
            example = "192.168.8.40";
          };

          asn = mkOption {
            type = types.int;
            description = "Peer AS number";
            example = 64512;
          };

          description = mkOption {
            type = types.str;
            description = "Description of the peer";
            default = "";
            example = "MetalLB speaker on master-01";
          };
        };
      });
      default = [];
      description = "List of BGP peers (MetalLB speakers)";
    };

    networks = mkOption {
      type = types.listOf (types.submodule {
        options = {
          network = mkOption {
            type = types.str;
            description = "Network to advertise via BGP";
            example = "10.45.0.0/16";
          };

          description = mkOption {
            type = types.str;
            description = "Description of the network";
            default = "";
            example = "MetalLB LoadBalancer IP range";
          };
        };
      });
      default = [];
      description = "Networks to advertise via BGP";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional FRR BGP configuration";
    };

    interface = mkOption {
      type = types.str;
      description = "Interface to bind BGP to";
      default = "lan";
      example = "lan";
    };

    logLevel = mkOption {
      type = types.enum ["emergencies" "alerts" "critical" "errors" "warnings" "notifications" "informational" "debugging"];
      default = "informational";
      description = "BGP logging level";
    };
  };

  config = mkIf cfg.enable {
    # Enable FRR BGP daemon
    services.frr = {
      bgpd = {
        enable = true;
        options = [
          "--log-level=${cfg.logLevel}"
        ];
      };

      config = ''
        !
        ! BGP Configuration for MetalLB
        !
        log syslog ${cfg.logLevel}
        !
        router bgp ${toString cfg.localASN}
         bgp router-id ${cfg.routerId}
         bgp bestpath as-path multipath-relax
         bgp bestpath compare-routerid
         !
         ! Advertise networks
        ${concatMapStringsSep "\n" (net: " network ${net.network}${optionalString (net.description != "") " ! ${net.description}"}") cfg.networks}
         !
         ! BGP peers (MetalLB speakers)
        ${concatMapStringsSep "\n" (peer: ''
         neighbor ${peer.address} remote-as ${toString peer.asn}
         neighbor ${peer.address} description ${if peer.description != "" then peer.description else "BGP peer ${peer.address}"}
         neighbor ${peer.address} activate
         neighbor ${peer.address} soft-reconfiguration inbound'') cfg.peers}
         !
        ${cfg.extraConfig}
        !
        exit
        !
      '';
    };

    # Enable IP forwarding (required for routing)
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkDefault 1;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
    };

  };
}
