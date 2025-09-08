# Observability with Vector and Grafana Cloud

This document describes the comprehensive observability solution implemented using Vector for log and metrics shipping to Grafana Cloud, with Prometheus exporters for system metrics.

## Architecture Overview

The observability stack consists of:

- **Vector**: Central log and metrics shipping agent with API debugging
- **Prometheus Exporters**: System metrics collection (node, BIND, FRR)
- **Grafana Cloud**: Remote storage for logs (Loki) and metrics (Prometheus)
- **SOPS**: Encrypted secrets management for API keys
- **Advanced Log Parsing**: Router-specific parsing for DHCP, DNS, and BGP logs

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│ Router/Server   │    │    Vector    │    │  Grafana Cloud  │
│                 │    │   (API:8686) │    │                 │
│ ┌─────────────┐ │    │              │    │ ┌─────────────┐ │
│ │ journald    │─┼────┼─ Log Parse ──┼────┼─│    Loki     │ │
│ │ (logs)      │ │    │ DHCP/DNS/BGP │    │ │   (logs)    │ │
│ └─────────────┘ │    │              │    │ └─────────────┘ │
│                 │    │              │    │                 │
│ ┌─────────────┐ │    │              │    │ ┌─────────────┐ │
│ │node-exporter│─┼────┼─ Scrape ─────┼────┼─│ Prometheus  │ │
│ │bind-exporter│ │    │              │    │ │ (metrics)   │ │
│ │frr-exporter │ │    │              │    │ └─────────────┘ │
│ └─────────────┘ │    │              │    │                 │
└─────────────────┘    └──────────────┘    └─────────────────┘
```

## Components

### Vector
- **Primary log and metrics shipper**
- Collects from systemd journal and Prometheus exporters
- Ships to Grafana Cloud Loki (logs) and Prometheus (metrics)
- Adds consistent labeling and parsing

### Prometheus Exporters
- **node-exporter**: System metrics (CPU, memory, disk, network)
- **bind-exporter**: DNS server metrics (queries, zones, cache)
- **frr-exporter**: BGP routing metrics (peers, routes, state)

## Configuration

### 1. SOPS Secrets Setup

Ensure your `secrets/users.yaml` contains:

```yaml
prom-user: "1111111"      # Your Grafana Cloud Prometheus user ID
loki-user: "1111111"      # Your Grafana Cloud Loki user ID
grafana-key: "your-api-key-here"  # Your Grafana Cloud API key
```

### 2. Router Configuration

For routers using the `services.router` module:

```nix
## Configuration Structure

### Core Module: `modules/nixos/observability.nix`

Provides the main observability configuration with:

- Vector service configuration with API debugging enabled
- SOPS integration for Grafana Cloud credentials
- Prometheus exporter configurations
- Advanced log transforms for structured logging

### Server Personality: `nixos/personalities/server/observability.nix`

Default configuration for servers including:

- Grafana Cloud endpoints (US East 2 region)
- Default exporter settings
- Server-specific labels

### Router Integration: `modules/nixos/router.nix`

Router module includes integrated observability with:

- Advanced log parsing for DHCP, DNS, and BGP events
- Router-specific exporter configuration
- Conditional enablement based on service configuration

## Secrets Management

### SOPS Configuration

Secrets are stored in `secrets/users.yaml` and include:

```yaml
vector: |
  {
    "grafana_key": "glc_...",
    "prom_user": "2661377",
    "loki_user": "1326365"
  }
```

### Required Grafana Cloud API Key Scopes

The API key must have these permissions:

- **`metrics:write`**: For Prometheus remote write
- **`logs:write`**: For Loki log ingestion

⚠️ **Common Issue**: "authentication error: invalid scope requested" indicates insufficient API key permissions.

### Vector Secrets Integration

Vector uses systemd credentials with JSON secrets:

```nix
systemd.services.vector.serviceConfig.LoadCredential = "grafana:${config.sops.secrets."vector".path}";

secret = {
  grafana = {
    type = "file";
    path = "/run/credentials/vector.service/grafana";
  };
};
```

References in Vector config use: `SECRET[grafana.grafana_key]`, `SECRET[grafana.prom_user]`, etc.

## Usage Examples

### Enable Observability on Servers

```nix
# nixos/hosts/{hostname}/default.nix
{
  imports = [
    ../../personalities/server/observability.nix
  ];

  # Server automatically gets node exporter enabled
}
```

### Enable Observability on Routers

```nix
# Router observability is automatically configured based on services
services.router = {
  enable = true;
  vlans = [ ... ]; # Enables BIND exporter
};

services.bgp.enable = true; # Enables FRR exporter
```

### Custom Labels and Configuration

```nix
services.observability = {
  vector.extraLabels = {
    environment = "production";
    site = "datacenter-1";
    tier = "critical";
  };
};
```

This will automatically:
- Enable node, bind, and frr exporters (if applicable)
- Parse DHCP, DNS, and BGP logs
- Add router-specific labels

### 3. Server Configuration

For regular servers:

```nix
{
  imports = [
    ../../personalities/base
    ../../personalities/server  # Includes observability module
  ];

  services.observability = {
    enable = true;

    grafana = {
      prometheusEndpoint = "https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push";
      lokiEndpoint = "https://logs-prod-006.grafana.net/loki/api/v1/push";
      prometheusUser = "1111111";
      lokiUser = "1111111";
    };

    exporters = {
      node = true;    # System metrics
      bind = false;   # No DNS server
      frr = false;    # No routing
    };

    vector.extraLabels = {
      environment = "production";
      site = "nwk2";
      function = "backup-server";
    };
  };
}
```

### 4. Desktop/Workstation Configuration

For desktop systems:

```nix
{
  imports = [
    ../../personalities/desktop/wayland-wm/kde
    ../../personalities/server  # For observability only
  ];

  services.observability = {
    enable = true;

    grafana = {
      prometheusEndpoint = "https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push";
      lokiEndpoint = "https://logs-prod-006.grafana.net/loki/api/v1/push";
      prometheusUser = "1111111";
      lokiUser = "1111111";
    };

    exporters = {
      node = true;    # System metrics only
      bind = false;
      frr = false;
    };

    vector.extraLabels = {
      environment = "production";
      site = "nwk3";
      function = "workstation";
      user = "anthony";
    };
  };
}
```

## Grafana Cloud Endpoints

Update these endpoints based on your Grafana Cloud instance:

### EU West 2 (London)
- **Prometheus**: `https://prometheus-prod-24-prod-eu-west-2.grafana.net/api/prom/push`
- **Loki**: `https://logs-prod-006.grafana.net/loki/api/v1/push`

### US East 1 (Virginia)
- **Prometheus**: `https://prometheus-prod-01-prod-us-east-0.grafana.net/api/prom/push`
- **Loki**: `https://logs-prod-us-central1.grafana.net/loki/api/v1/push`

## Log Parsing

### Router Logs
- **DHCP**: Parses lease events (DISCOVER, OFFER, REQUEST, ACK, etc.)
- **DNS**: Parses query logs with client IP, query, and record type
- **BGP**: Parses neighbor state changes

### Common Labels
All logs include:
- `hostname`: System hostname
- `service`: systemd unit name
- `level`: Log priority/level
- Custom labels from `vector.extraLabels`

## Metrics Collection

### Node Exporter Metrics
- CPU usage, load average
- Memory usage and swap
- Disk I/O and space usage
- Network interface statistics
- systemd service states

### BIND Exporter Metrics
- DNS query rates by record type
- Zone transfer statistics
- Cache hit/miss ratios
- Query resolution times

### FRR Exporter Metrics
- BGP peer states and session info
- Route counts by protocol
- Interface statistics
- Neighbor uptime

## Deployment

1. **Update your host configuration** with observability settings
2. **Rebuild and deploy** your system:
   ```bash
   nix build .#nixosConfigurations.hostname.config.system.build.toplevel
   sudo nixos-rebuild switch --flake .#hostname
   ```
3. **Check services** are running:
   ```bash
   systemctl status vector
   systemctl status prometheus-node-exporter
   systemctl status prometheus-bind-exporter  # if enabled
   systemctl status prometheus-frr-exporter   # if enabled
   ```
4. **Verify logs** in Grafana Cloud Explore

## Monitoring the Setup

### Debugging and Monitoring

### Vector API Endpoints

Vector provides a built-in API for debugging and monitoring:

```bash
# Health check
curl http://127.0.0.1:8686/health

# Component status
curl -X POST http://127.0.0.1:8686/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "query { components { sources { name } sinks { name } } }"}'

# Configuration validation
sudo vector validate --config-toml /etc/vector/vector.toml
```

### Log Analysis

```bash
# Vector service logs
journalctl -fu vector

# Check credentials
ls -la /run/credentials/vector.service/

# Test endpoints manually
curl -u "USER_ID:API_KEY" "GRAFANA_ENDPOINT" -X POST
```

### Common Issues

1. **401 Unauthorized**: Check API key scopes and validity
2. **404 Not Found**: Verify Grafana Cloud endpoints and user IDs
3. **Connection failures**: Check network connectivity and firewall rules
4. **Secret access**: Ensure SOPS decryption and systemd credentials

### Validation Steps

```bash
# Test configuration build
nix build .#nixosConfigurations.{hostname}.config.system.build.toplevel

# Validate Vector config
sudo vector validate --config-toml /etc/vector/vector.toml

# Check service status
systemctl status vector prometheus-node-exporter

# Verify metrics endpoints
curl http://127.0.0.1:9100/metrics | head
```
```bash
# Check Vector status
systemctl status vector
journalctl -u vector -f

# Check exporter endpoints
curl http://127.0.0.1:9100/metrics  # node-exporter
curl http://127.0.0.1:9119/metrics  # bind-exporter (if enabled)
curl http://127.0.0.1:9342/metrics  # frr-exporter (if enabled)
```

### Grafana Cloud
- **Explore > Loki**: Query logs with `{hostname="your-host"}`
- **Explore > Prometheus**: Query metrics like `up{job="node"}`
- **Dashboards**: Import community dashboards for node-exporter, etc.

## Troubleshooting

### Vector Issues
```bash
# Check Vector config
vector validate --config-toml /etc/vector/vector.toml

# Check Vector logs
journalctl -u vector -f

# Test Vector connectivity
vector test --config-toml /etc/vector/vector.toml
```

### Exporter Issues
```bash
# Check if exporters are listening
ss -tlnp | grep -E ':(9100|9119|9342)'

# Check exporter logs
journalctl -u prometheus-node-exporter -f
```

### Authentication Issues
- Verify SOPS secrets are decrypted: `ls -la /run/secrets/`
- Check Vector has access to credentials: `systemctl show vector | grep Credential`
- Validate Grafana Cloud credentials in the web UI

## Router-Specific Configuration

Routers include advanced log parsing for network services integrated directly into the router module:

### DHCP Events

DHCP lease events from Kea are parsed into structured logs:

```bash
# Example DHCP lease logs
journalctl -u kea-dhcp4-server | grep "DHCPACK\|DHCPREQUEST"
```

Vector parses these into structured metrics with fields:
- `client_ip`, `mac_address`, `hostname`
- `lease_duration`, `subnet`
- `event_type` (DHCPACK, DHCPREQUEST, etc.)

### DNS Query Logs

BIND DNS queries are captured and structured:

```bash
# BIND query logs
journalctl -u bind | grep "query:"
```

Parsed into metrics with:
- `query_name`, `query_type`, `client_ip`
- `response_code`, `query_time`
- `recursion_desired`

### BGP State Changes

FRR BGP events are monitored for routing changes:

```bash
# FRR BGP events
journalctl -u frr | grep "bgp.*state change"
```

Captured with:
- `peer_ip`, `old_state`, `new_state`
- `asn`, `event_time`
- `neighbor_description`

## Deployment Process

1. **Configure secrets** in `secrets/users.yaml`:
   ```yaml
   grafana: |
     {
       "grafana_key": "your-api-key-with-metrics-write-and-logs-write-scopes",
       "prom_user": "your-prometheus-user-id",
       "loki_user": "your-loki-user-id"
     }
   ```

2. **Add observability** personality to host configuration:
   ```nix
   imports = [
     ../../personalities/server/observability.nix
   ];
   ```

3. **Build and deploy**:
   ```bash
   nixos-rebuild switch --flake .#hostname
   # or with deploy-rs
   deploy .#hostname
   ```

4. **Verify Vector** service:
   ```bash
   systemctl status vector
   curl http://127.0.0.1:8686/health
   ```

5. **Check Grafana Cloud** for incoming data in Explore sections

6. **Set up dashboards** and alerting as needed

## API Key Requirements

Your Grafana Cloud API key must have these scopes:
- `metrics:write` - For Prometheus metrics
- `logs:write` - For Loki logs

Create keys at: `https://grafana.com/orgs/YOUR_ORG/api-keys`

The observability stack is now fully integrated and operational!

## Security Considerations

- All exporters bind to `127.0.0.1` (localhost only)
- Grafana Cloud credentials stored encrypted with SOPS
- systemd credentials used for runtime secret access
- No sensitive data in Vector configuration files
