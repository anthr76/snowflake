# HAProxy for Kubernetes Control-plane Load Balancing

This configuration provides L4 TCP load balancing for Kubernetes control-plane nodes using HAProxy.

## Overview

The HAProxy setup includes:
- **Frontend**: Listens on port 6443 (Kubernetes API server port) on the router's Kubernetes VLAN IP
- **Backend**: Load balances traffic across multiple Kubernetes control-plane nodes
- **Health Checks**: TCP health checks to ensure only healthy nodes receive traffic
- **Statistics**: Web interface on port 8404 for monitoring

## DNS Configuration

The DNS entry `cluster-0.scr1.rabbito.tech` points to the router's IP on the Kubernetes VLAN (192.168.8.1), which HAProxy binds to for load balancing.

## Configuration

### fw1-scr1 Router Configuration

The router is configured with:
```nix
services.haproxy-k8s = {
  enable = true;
  frontendPort = 6443;
  bindAddress = "192.168.8.1"; # Router IP on kubernetes VLAN
  controlPlaneNodes = [
    # Add your Kubernetes control plane nodes here
    # Example:
    # {
    #   name = "k8s-master-1";
    #   address = "192.168.8.10";
    #   port = 6443;
    # }
    # {
    #   name = "k8s-master-2";
    #   address = "192.168.8.11";
    #   port = 6443;
    # }
    # {
    #   name = "k8s-master-3";
    #   address = "192.168.8.12";
    #   port = 6443;
    # }
  ];
  statsPort = 8404;
};
```

### DNS Records

The following DNS records are configured:
- `cluster-0.scr1.rabbito.tech` → `192.168.8.1` (A record)
- `cluster-0.scr1.rabbito.tech` → Added to Cloudflare DDNS domains

## Setting Up Control Plane Nodes

1. **Add your control plane nodes** to the `controlPlaneNodes` list in `/nixos/hosts/fw1-scr1/default.nix`
2. **Deploy the configuration** with `nixos-rebuild switch`
3. **Configure your Kubernetes cluster** to use `cluster-0.scr1.rabbito.tech:6443` as the API server endpoint

### Example Control Plane Node Configuration

```nix
controlPlaneNodes = [
  {
    name = "k8s-master-1";
    address = "192.168.8.10";
    port = 6443;
  }
  {
    name = "k8s-master-2";
    address = "192.168.8.11";
    port = 6443;
  }
  {
    name = "k8s-master-3";
    address = "192.168.8.12";
    port = 6443;
  }
];
```

## Monitoring

HAProxy statistics are available at:
- **Internal**: `http://192.168.8.1:8404/stats`
- **External**: `http://cluster-0.scr1.rabbito.tech:8404/stats` (if accessible)

## Firewall Ports

The following ports are automatically opened:
- **6443/tcp**: Kubernetes API server (frontend)
- **8404/tcp**: HAProxy statistics interface

## Health Checks

HAProxy performs TCP health checks on each backend server:
- **Connection timeout**: 10 seconds
- **Check interval**: Configurable via HAProxy defaults
- **Retry policy**: 3 retries before marking a server down

## Kubernetes Client Configuration

Update your kubeconfig or cluster setup to use:
```yaml
server: https://cluster-0.scr1.rabbito.tech:6443
```

## Troubleshooting

### Check HAProxy Status
```bash
systemctl status haproxy
```

### View HAProxy Logs
```bash
journalctl -u haproxy -f
```

### Test Connectivity
```bash
# Test the load balancer endpoint
curl -k https://cluster-0.scr1.rabbito.tech:6443/version

# Check individual backend servers
curl -k https://192.168.8.10:6443/version
curl -k https://192.168.8.11:6443/version
curl -k https://192.168.8.12:6443/version
```

### View HAProxy Statistics
Navigate to `http://192.168.8.1:8404/stats` to see:
- Backend server status
- Connection statistics
- Health check results
- Load balancing distribution

## Network Topology

```
Internet
    ↓
Router (fw1-scr1) - 192.168.8.1
    ↓ HAProxy :6443
    ├── k8s-master-1 (192.168.8.10:6443)
    ├── k8s-master-2 (192.168.8.11:6443)
    └── k8s-master-3 (192.168.8.12:6443)
```

## Security Considerations

1. **TLS Termination**: HAProxy operates at L4, so TLS encryption is preserved end-to-end
2. **Network Isolation**: Control plane nodes should be on the dedicated Kubernetes VLAN (192.168.8.0/24)
3. **Firewall Rules**: Only necessary ports are exposed
4. **Statistics Interface**: Consider restricting access to the statistics interface in production

## Future Enhancements

- Add support for multiple clusters
- Implement automatic backend server discovery
- Add Prometheus metrics export
- Configure SSL/TLS health checks for better validation
