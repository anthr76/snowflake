{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.bgp;
in {
  options.services.bgp = {
    enable = mkEnableOption "BGP daemon for K8s BGP support";

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

    peerGroupName = mkOption {
      type = types.str;
      description = "Name of the BGP peer group";
      default = "k8s";
    };

    peerASN = mkOption {
      type = types.int;
      description = "Remote AS number for peers";
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

          description = mkOption {
            type = types.str;
            description = "Description of the peer";
            default = "";
            example = "K8s BGP speaker on master-01";
          };
        };
      });
      default = [];
      description = "List of BGP peers (K8s BGP speakers)";
    };

    nextHopSelf = mkOption {
      type = types.bool;
      description = "Advertise this router as next hop for all peers in the peer group";
      default = true;
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Additional FRR BGP configuration";
    };

    logLevel = mkOption {
      type = types.enum ["emergencies" "alerts" "critical" "errors" "warnings" "notifications" "informational" "debugging"];
      default = "informational";
      description = "BGP logging level";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Open firewall for BGP traffic and allow forwarding";
    };
  };

  config = mkIf cfg.enable {
    # Enable FRR BGP daemon and Zebra for route installation
    services.frr = {
      bgpd = {
        enable = true;
      };

      config = ''
        !
        ! BGP Configuration for K8s BGP
        !
        log syslog ${cfg.logLevel}
        !
        ! Route-map definitions (must come before router bgp)
        route-map ALLOW-ALL permit 10
        !
        router bgp ${toString cfg.localASN}
         bgp router-id ${cfg.routerId}
         maximum-paths 4
         bgp ebgp-requires-policy
         !
         ! Peer group configuration
         neighbor ${cfg.peerGroupName} peer-group
         neighbor ${cfg.peerGroupName} remote-as ${toString cfg.peerASN}
         neighbor ${cfg.peerGroupName} activate
         neighbor ${cfg.peerGroupName} soft-reconfiguration inbound
         !
         ! BGP peers
        ${concatMapStringsSep "\n" (peer: " neighbor ${peer.address} peer-group ${cfg.peerGroupName}") cfg.peers}
         !
         address-family ipv4 unicast
          redistribute connected
          neighbor ${cfg.peerGroupName} activate
          neighbor ${cfg.peerGroupName} route-map ALLOW-ALL in
          neighbor ${cfg.peerGroupName} route-map ALLOW-ALL out
          neighbor ${cfg.peerGroupName} next-hop-self
        exit-address-family
        !
        ${cfg.extraConfig}
      '';
    };

    # Enable IP forwarding (required for routing)
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = lib.mkDefault 1;
      "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 179 ];
    };
  };
}
