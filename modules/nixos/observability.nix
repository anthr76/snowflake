{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.observability;
in {
  options.services.observability = {
    enable = mkEnableOption "Observability stack with Vector and Prometheus exporters";

    grafana = {
      prometheusEndpoint = mkOption {
        type = types.str;
        description = "Grafana Cloud Prometheus endpoint";
        example = "https://prometheus-prod-56-prod-us-east-2.grafana.net/api/prom/push";
      };

      lokiEndpoint = mkOption {
        type = types.str;
        description = "Grafana Cloud Loki endpoint";
        example = "https://logs-prod-036.grafana.net";
      };

      prometheusUser = mkOption {
        type = types.str;
        description = "Grafana Cloud Prometheus user ID";
      };

      lokiUser = mkOption {
        type = types.str;
        description = "Grafana Cloud Loki user ID";
      };
    };

    exporters = {
      node = mkEnableOption "Node exporter for system metrics";
      bind = mkEnableOption "BIND DNS exporter";
      frr = mkEnableOption "FRR routing exporter";
    };

    vector = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable Vector for log and metrics shipping";
      };

      extraLabels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Extra labels to add to all metrics and logs";
        example = {
          environment = "production";
          datacenter = "home";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    # SOPS secrets for Grafana Cloud credentials
    sops.secrets = {
      "vector" = {
        sopsFile = ../../secrets/users.yaml;
        mode = "0400";
      };
    };
    systemd.services.vector.serviceConfig.LoadCredential = "grafana:${config.sops.secrets."vector".path}";


    # Vector configuration for shipping logs and metrics
    services.vector = mkIf cfg.vector.enable {
      enable = true;
      journaldAccess = true;
      settings = {
        # Enable API for debugging
        api = {
          enabled = true;
          address = "127.0.0.1:8686";
        };

        # Configure secrets provider for SOPS integration
        secret = {
          grafana = {
            type = "file";
            path = "/run/credentials/vector.service/grafana";
          };
        };

        # Enable internal metrics and logging
        data_dir = "/var/lib/vector";
        log_schema = {
          host_key = "host";
          message_key = "message";
          timestamp_key = "timestamp";
        };

        # Sources
        sources = {
          # System journal logs
          journald = {
            type = "journald";
            journal_directory = "/var/log/journal";
            current_boot_only = false;
          };

          # Prometheus metrics from local exporters
          prometheus_scrape = {
            type = "prometheus_scrape";
            endpoints = [
              "http://127.0.0.1:9100/metrics"  # node-exporter
            ] ++ optionals cfg.exporters.bind [
              "http://127.0.0.1:9119/metrics"  # bind-exporter
            ] ++ optionals cfg.exporters.frr [
              "http://127.0.0.1:9342/metrics"  # frr-exporter
            ];
            scrape_interval_secs = 30;
          };
        };

        # Transforms
        transforms = {
          # Add common labels to logs
          log_labels = {
            type = "remap";
            inputs = ["journald"];
            source = ''
              .hostname = "${config.networking.hostName}"
              .fqdn = "${config.networking.hostName}.${config.networking.domain}"

              # Ensure _SYSTEMD_UNIT field exists with fallback
              if !exists(._SYSTEMD_UNIT) {
                ._SYSTEMD_UNIT = "unknown"
              }

              ${concatStringsSep "\n" (mapAttrsToList (k: v: ".${k} = \"${v}\"") cfg.vector.extraLabels)}
            '';
          };

          # Add common labels to metrics
          metric_labels = {
            type = "remap";
            inputs = ["prometheus_scrape"];
            source = ''
              .tags.hostname = "${config.networking.hostName}"
              .tags.fqdn = "${config.networking.hostName}.${config.networking.domain}"

              .tags.instance = "${config.networking.hostName}.${config.networking.domain}"

              # Override nodename label with FQDN for node-exporter metrics that have it
              if exists(.tags.nodename) {
                .tags.nodename = "${config.networking.hostName}.${config.networking.domain}"
              }

              ${concatStringsSep "\n" (mapAttrsToList (k: v: ".tags.${k} = \"${v}\"") cfg.vector.extraLabels)}
            '';
          };
        };

        # Sinks
        sinks = {
          # Ship logs to Grafana Cloud Loki
          loki = {
            type = "loki";
            inputs = ["log_labels"];
            endpoint = cfg.grafana.lokiEndpoint;
            path = "/loki/api/v1/push";
            encoding = {
              codec = "json";
            };
            auth = {
              strategy = "basic";
              user = "SECRET[grafana.loki_user]";
              password = "SECRET[grafana.grafana_key]";
            };
            labels = {
              hostname = "{{ hostname }}";
              fqdn = "{{ fqdn }}";
              service = "{{ _SYSTEMD_UNIT }}";
              level = "{{ PRIORITY }}";
            };
            remove_label_fields = true;
            compression = "gzip";
            # Add request configuration for better debugging
            request = {
              timeout_secs = 60;
              retry_attempts = 3;
              retry_initial_backoff_secs = 1;
              retry_max_duration_secs = 300;
            };
          };

          # Ship metrics to Grafana Cloud Prometheus
          prometheus_remote_write = {
            type = "prometheus_remote_write";
            inputs = ["metric_labels"];
            endpoint = cfg.grafana.prometheusEndpoint;
            auth = {
              strategy = "basic";
              user = "SECRET[grafana.prom_user]";
              password = "SECRET[grafana.grafana_key]";
            };
            # Disable healthcheck as it's causing 405 errors
            healthcheck = {
              enabled = false;
            };
            # default_namespace = "nixos";
            # Add request configuration for better debugging
            request = {
              timeout_secs = 60;
              retry_attempts = 3;
              retry_initial_backoff_secs = 1;
              retry_max_duration_secs = 300;
            };
          };
        };
      };
    };

    # Prometheus exporters
    services.prometheus.exporters = {
      # Node exporter for system metrics
      node = mkIf cfg.exporters.node {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9100;
      };

      # BIND DNS server metrics
      bind = mkIf cfg.exporters.bind {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9119;
        bindURI = "http://127.0.0.1:8053/";
      };

      # FRR routing metrics
      frr = mkIf cfg.exporters.frr {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9342;
      };
    };

    # Firewall configuration - only allow local access to exporters
    networking.firewall = {
      interfaces.lo = {
        allowedTCPPorts = [
          9100  # node-exporter
          8686  # vector-api
        ] ++ optionals cfg.exporters.bind [
          9119  # bind-exporter
          8053  # bind statistics
        ] ++ optionals cfg.exporters.frr [
          9342  # frr-exporter
        ];
      };
    };
  };
}
