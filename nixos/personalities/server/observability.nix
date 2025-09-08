{
  ...
}: {
  # Default observability configuration for servers
  services.observability = {
    enable = true;

    # Default Grafana Cloud endpoints (US East 2)
    grafana = {
      prometheusEndpoint = "https://prometheus-prod-56-prod-us-east-2.grafana.net/api/prom/push";
      lokiEndpoint = "https://logs-prod-036.grafana.net/";
    };

    # Default exporters for servers
    exporters = {
      node = true;    # Always enable system metrics for servers
      bind = false;   # Disabled by default, enable per host if needed
      frr = false;    # Disabled by default, enable per host if needed
    };
  };
}
