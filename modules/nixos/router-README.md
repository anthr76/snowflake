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

### Static DHCP Reservations

Static DHCP reservations ensure that specific devices always receive the same IP address. You can configure reservations at multiple levels:

1. **Per-VLAN reservations**: Configured within each VLAN
2. **Global reservations**: Applied across all subnets
3. **Network-specific reservations**: For LAN and OOB networks

```nix
{
  services.router = {
    enable = true;
    domain = "example.rabbito.tech";

    # Global static reservations (apply to any subnet)
    globalStaticReservations = [
      {
        hostname = "gateway";
        mac = "aa:bb:cc:dd:ee:ff";
        ip = "192.168.1.1";
      }
    ];

    # LAN network static reservations
    lanStaticReservations = [
      {
        hostname = "main-server";
        mac = "11:22:33:44:55:66";
        ip = "192.168.1.10";
      }
    ];

    # OOB network static reservations
    oobStaticReservations = [
      {
        hostname = "switch-mgmt";
        mac = "77:88:99:aa:bb:cc";
        ip = "10.10.10.10";
      }
    ];

    vlans = [
      {
        id = 10;
        name = "servers";
        subnet = "192.168.10.0/24";
        router = "192.168.10.1";

        # Per-VLAN static reservations
        staticReservations = [
          {
            hostname = "database-server";
            mac = "12:34:56:78:9a:bc";
            ip = "192.168.10.50";
          }
          {
            hostname = "web-server";
            mac = "de:ad:be:ef:ca:fe";
            ip = "192.168.10.51";
          }
        ];
      }
    ];
  };
}
```

### Custom DNS Records

The router module supports adding custom DNS records to your domain zone, as well as creating entirely separate DNS zones. This is useful for internal services, custom hostnames, and service discovery.

#### Adding Records to Main Domain

```nix
{
  services.router = {
    enable = true;
    domain = "example.rabbito.tech";

    # Custom DNS records for the main domain
    dnsRecords = [
      # A records for servers
      {
        name = "webserver";
        type = "A";
        value = "192.168.10.50";
        ttl = 3600;
      }
      {
        name = "database";
        type = "A";
        value = "192.168.10.51";
      }

      # CNAME aliases
      {
        name = "www";
        type = "CNAME";
        value = "webserver";
      }
      {
        name = "db";
        type = "CNAME";
        value = "database";
      }

      # MX record for mail
      {
        name = "mail";
        type = "MX";
        value = "mail.example.com.";
        priority = 10;
      }

      # TXT records for verification
      {
        name = "_verification";
        type = "TXT";
        value = "v=spf1 include:_spf.google.com ~all";
      }
    ];
  };
}
```

#### Creating Custom DNS Zones

```nix
{
  services.router = {
    enable = true;
    domain = "example.rabbito.tech";

    # Custom internal zones
    customDnsZones = {
      "internal.local" = {
        ttl = 300; # 5 minute TTL for internal records
        soaEmail = "admin.internal.local";
        records = [
          { name = "server1"; type = "A"; value = "10.0.0.10"; }
          { name = "server2"; type = "A"; value = "10.0.0.11"; }
          { name = "lb"; type = "A"; value = "10.0.0.100"; }
          { name = "api"; type = "CNAME"; value = "lb"; }
        ];
      };

      "k8s.local" = {
        records = [
          { name = "master"; type = "A"; value = "192.168.8.10"; }
          { name = "worker1"; type = "A"; value = "192.168.8.11"; }
          { name = "worker2"; type = "A"; value = "192.168.8.12"; }
          { name = "ingress"; type = "A"; value = "192.168.8.100"; }
        ];
      };
    };
  };
}
```

#### Supported Record Types

- **A**: IPv4 address record
- **AAAA**: IPv6 address record
- **CNAME**: Canonical name (alias) record
- **MX**: Mail exchange record (requires `priority`)
- **TXT**: Text record for verification/configuration
- **SRV**: Service record (requires `priority`)
- **PTR**: Pointer record for reverse DNS

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
- `staticReservations`: List of static DHCP reservations for this VLAN
- `clientClass`: DHCP client class for vendor-specific options
- `enabled`: Whether this VLAN is enabled (default: true)

### Optional Configuration

- `managementNetwork`: Management network subnet
- `lanInterface`: LAN interface name (default: "lan")
- `wanInterface`: WAN interface name (default: "wan")
- `oobInterface`: Out-of-band management interface name (default: "oob")
- `enableOob`: Enable OOB management interface (default: true)
- `enableLan`: Enable LAN interface with IP assignment (default: true)
- `udevRules`: Custom udev rules for interface naming
- `cloudflaredomains`: Domains to update via Cloudflare DDNS
- `tailscaleRoutes`: Routes to advertise via Tailscale
- `forwardZones`: DNS forward zones for other networks
- `customDhcpOptions`: Additional DHCP options
- `customBindConfig`: Additional BIND DNS configuration
- `globalStaticReservations`: Global static DHCP reservations
- `lanStaticReservations`: Static reservations for LAN network
- `oobStaticReservations`: Static reservations for OOB network
- `dnsRecords`: Custom DNS records for the main domain zone
- `customDnsZones`: Additional DNS zones with custom records

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
