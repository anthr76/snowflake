{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.services.haproxy-k8s;
in {
  options.services.haproxy-k8s = {
    enable = mkEnableOption "HAProxy for Kubernetes control-plane load balancing";

    frontendPort = mkOption {
      type = types.int;
      default = 6443;
      description = "Port for the HAProxy frontend (Kubernetes API server port)";
    };

    controlPlaneNodes = mkOption {
      type = types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Name of the control plane node";
          };
          address = mkOption {
            type = types.str;
            description = "IP address of the control plane node";
          };
          port = mkOption {
            type = types.int;
            default = 6443;
            description = "Port of the Kubernetes API server on this node";
          };
        };
      });
      default = [];
      description = "List of Kubernetes control plane nodes to load balance";
    };

    statsPort = mkOption {
      type = types.int;
      default = 8404;
      description = "Port for HAProxy statistics interface";
    };

    bindAddress = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind HAProxy to";
    };


  };

  config = mkIf cfg.enable {

    services.haproxy = {
      enable = true;
      config = ''
        defaults
          timeout connect 10ms
          mode                    http
          log                     global
          option                  httplog
          option                  dontlognull
          option http-server-close
          option                  redispatch
          retries                 1
          timeout http-request    10s
          timeout queue           20s
          timeout connect         5s
          timeout client          35s
          timeout server          35s
          timeout http-keep-alive 10s
          timeout check           10s

        global
          ssl-server-verify none

        # Kubernetes API Server Load Balancer
        # Uses HTTP health checks on /healthz endpoint
        # Accepts both 200 (authenticated) and 401 (unauthenticated) as healthy
        frontend kubernetes-api
          bind ${cfg.bindAddress}:${toString cfg.frontendPort}
          mode tcp
          option tcplog
          default_backend kubernetes-masters

        backend kubernetes-masters
          option httpchk
          http-check connect ssl
          http-check send meth GET uri /healthz
          http-check expect status 200,401
          mode tcp
          balance     roundrobin
          ${concatMapStringsSep "\n  " (node:
            "server ${node.name} ${node.address}:${toString node.port} check"
          ) cfg.controlPlaneNodes}
      '';
    };    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      cfg.frontendPort
      cfg.statsPort
    ];

    # Create haproxy user and group
    users.users.haproxy = {
      group = "haproxy";
      isSystemUser = true;
      home = "/var/lib/haproxy";
      createHome = true;
    };

    users.groups.haproxy = {};
  };
}
