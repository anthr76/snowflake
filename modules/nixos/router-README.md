# Router Module

This module provides a standardized configuration for Rabbito network routers with consistent VLAN layouts across multiple sites.

## Features

- **Standardized VLAN Layout**: Consistent VLAN IDs across all sites
  - VLAN 100: End Users
  - VLAN 10: Servers
  - VLAN 8: Kubernetes (optional)
  - VLAN 99: Management
  - VLAN 101: Guests

- **Automated Configuration**: Automatically configures:
  - DHCP server with appropriate pools
  - DNS server with forward and reverse zones
  - Dynamic DNS updates
  - NAT and firewall rules
  - Tailscale route advertisement
  - Cloudflare DDNS

- **Site Customization**: Easy per-site customization of:
  - Network subnets
  - Interface MAC address mapping
  - Cloudflare domains
  - DNS forward zones
  - Tailscale routes

## Usage

### Basic Configuration

```nix
{
  services.rabbito-router = {
    enable = true;
    domain = "nwk3.rabbito.tech";
    managementNetwork = "10.40.99.0/24";

    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d9", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d8", NAME="wan"
    '';

    cloudflaredomains = [
      "fw-1.nwk3.rabbito.tech"
      "nwk3.rabbito.tech"
    ];

    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.17.0/24";
        router = "192.168.17.1";
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.16.0/24";
        router = "192.168.16.1";
      }
      {
        id = 99;
        name = "management";
        subnet = "10.40.99.0/24";
        router = "10.40.99.1";
        clientClass = "ubnt";
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.14.0/24";
        router = "192.168.14.1";
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.13.0/24";
        router = "192.168.13.1";
      }
    ];
  };
}
```

### Advanced Configuration

```nix
{
  services.rabbito-router = {
    enable = true;
    domain = "example.rabbito.tech";
    managementNetwork = "10.50.99.0/24";

    # Custom DHCP options
    customDhcpOptions = [
      {
        name = "time-servers";
        data = "pool.ntp.org";
      }
    ];

    # DNS forward zones for other networks
    forwardZones = {
      "other-site.rabbito.tech" = {
        forwarders = [ "10.60.99.1" ];
      };
    };

    # Tailscale route advertisement
    tailscaleRoutes = [
      "192.168.20.0/24"
      "10.50.99.0/24"
    ];

    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.22.0/24";
        router = "192.168.22.1";
        enabled = false;  # Disable Kubernetes VLAN
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.20.0/24";
        router = "192.168.20.1";
        dhcpPool = "192.168.20.50 - 192.168.20.200";  # Custom DHCP range
      }
      # ... other VLANs
    ];
  };
}
```

## Configuration Options

### Required Options

- `enable`: Enable the router module
- `domain`: The domain name for this network (e.g., "nwk3.rabbito.tech")
- `vlans`: List of VLAN configurations

### VLAN Configuration

Each VLAN must specify:
- `id`: VLAN ID (integer)
- `name`: Descriptive name
- `subnet`: Network subnet in CIDR notation
- `router`: Router IP address for this VLAN

Optional VLAN settings:
- `dhcpPool`: Custom DHCP pool range (default: .20-.240)
- `clientClass`: DHCP client class for vendor-specific options
- `enabled`: Whether this VLAN is enabled (default: true)

### Optional Configuration

- `managementNetwork`: Management network subnet
- `lanInterface`: LAN interface name (default: "lan")
- `wanInterface`: WAN interface name (default: "wan")
- `udevRules`: Custom udev rules for interface naming
- `cloudflaredomains`: Domains to update via Cloudflare DDNS
- `tailscaleRoutes`: Routes to advertise via Tailscale
- `forwardZones`: DNS forward zones for other networks
- `customDhcpOptions`: Additional DHCP options
- `customBindConfig`: Additional BIND DNS configuration

## Migration from Legacy Configuration

To migrate existing router configurations:

1. Create a new configuration file using the module
2. Copy VLAN definitions from the old configuration
3. Copy interface MAC addresses to `udevRules`
4. Copy Cloudflare domains and Tailscale routes
5. Test the new configuration in a staging environment
6. Replace the old configuration file

## Standard VLAN Layout

| VLAN ID | Purpose | Typical Subnet | Description |
|---------|---------|----------------|-------------|
| 100 | End Users | 192.168.x.0/24 | User devices, workstations |
| 10 | Servers | 192.168.x.0/24 | Infrastructure servers |
| 8 | Kubernetes | 192.168.x.0/24 | Kubernetes cluster (optional) |
| 99 | Management | 10.x.99.0/24 | Network management devices |
| 101 | Guests | 192.168.x.0/24 | Guest network access |

## Benefits

1. **Consistency**: Same VLAN layout across all sites
2. **Reduced Duplication**: Common configuration shared via module
3. **Easier Maintenance**: Updates to common functionality propagate to all sites
4. **Site Flexibility**: Easy per-site customization where needed
5. **Documentation**: Self-documenting configuration with clear options
