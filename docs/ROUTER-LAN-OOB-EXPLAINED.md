# Router Module with LAN Trunk and OOB Configuration

## Network Interface Layout

The router module now supports a proper enterprise router configuration with:

### 1. **LAN Interface (Trunk Port)**
- **Purpose**: Physical interface that carries all VLAN traffic + base network
- **Configuration**: Gets its own IP address (e.g., 192.168.1.1/24)
- **Function**:
  - Serves as trunk port for all VLANs (vlan8, vlan10, vlan99, etc.)
  - Provides base network for non-VLAN traffic
  - Handles DHCP for the base 192.168.1.0/24 network

### 2. **VLAN Interfaces**
- **Purpose**: Virtual interfaces for network segmentation
- **Configuration**: Created on top of LAN trunk interface
- **Examples**:
  - `vlan8` (Kubernetes) → 192.168.22.1/24
  - `vlan10` (Servers) → 192.168.21.1/24
  - `vlan99` (Management) → 10.50.99.1/24
  - `vlan100` (End Users) → 192.168.20.1/24
  - `vlan101` (Guests) → 192.168.23.1/24

### 3. **OOB Interface (Out-of-Band)**
- **Purpose**: Separate physical interface for emergency management
- **Configuration**: Gets its own IP address (e.g., 10.10.10.1/24)
- **Function**:
  - Emergency access when main network fails
  - Independent of VLAN configuration
  - Always available for troubleshooting

## Example Configuration

```nix
services.router = {
  enable = true;
  domain = "example.rabbito.tech";

  # Interface naming (customize MAC addresses for your hardware)
  udevRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:ff", NAME="lan"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:fe", NAME="wan"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="aa:bb:cc:dd:ee:fd", NAME="oob"
  '';

  # LAN trunk port (carries VLANs + base network)
  enableLan = true;
  lanInterface = "lan";
  lanSubnet = "192.168.1.0/24";
  lanAddress = "192.168.1.1";

  # OOB emergency access
  enableOob = true;
  oobInterface = "oob";
  oobSubnet = "10.10.10.0/24";
  oobAddress = "10.10.10.1";

  # VLANs (created on LAN trunk)
  vlans = [
    { id = 8; name = "kubernetes"; subnet = "192.168.22.0/24"; router = "192.168.22.1"; }
    { id = 10; name = "servers"; subnet = "192.168.21.0/24"; router = "192.168.21.1"; }
    { id = 99; name = "management"; subnet = "10.50.99.0/24"; router = "10.50.99.1"; }
    { id = 100; name = "endusers"; subnet = "192.168.20.0/24"; router = "192.168.20.1"; }
    { id = 101; name = "guests"; subnet = "192.168.23.0/24"; router = "192.168.23.1"; }
  ];
};
```

## Network Flow

```
┌─────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Internet  │────│     WAN      │────│   Router/FW1    │
└─────────────┘    └──────────────┘    └─────────────────┘
                                                │
                         ┌──────────────────────┼────────────────────┐
                         │                      │                    │
                   ┌──────▼──────┐      ┌──────▼──────┐     ┌───────▼──────┐
                   │     LAN     │      │     OOB     │     │   Tailscale  │
                   │192.168.1.1  │      │ 10.10.10.1  │     │              │
                   │   (Trunk)   │      │ (Emergency) │     │              │
                   └──────┬──────┘      └─────────────┘     └──────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼────┐     ┌─────▼─────┐    ┌─────▼─────┐
    │ VLAN 8  │     │ VLAN 10   │    │ VLAN 99   │  ...
    │K8s      │     │ Servers   │    │Management │
    │.22.1/24 │     │ .21.1/24  │    │10.50.99.1 │
    └─────────┘     └───────────┘    └───────────┘
```

## Features Provided

### Automatic Configuration
- **DHCP**: Each interface/VLAN gets its own DHCP pool
- **DNS**: Forward and reverse DNS zones for all networks
- **Firewall**: Proper trusted interfaces and WAN access rules
- **NAT**: All internal networks NATed through WAN
- **Routing**: Kernel routing between all networks

### Management
- **Tailscale**: Route advertisement for all networks
- **Cloudflare DDNS**: Dynamic DNS updates
- **SSH Access**: Available on WAN interface (port 22)
- **Emergency Access**: Always available via OOB interface

## Benefits

1. **Enterprise-Grade**: Proper VLAN trunking like commercial routers
2. **Emergency Access**: OOB interface works independently of main network
3. **Flexibility**: Can disable OOB or LAN base network if not needed
4. **Consistency**: Same configuration across all sites
5. **Maintainability**: Centralized in one module

## Physical Setup

```
Router Hardware:
├── WAN Port     → Internet connection
├── LAN Port     → Switch (trunk: VLANs + base 192.168.1.0/24)
└── OOB Port     → Direct connection for emergency access
```

This setup provides both the enterprise functionality you need (VLAN trunking) and the emergency access capability (OOB management) in a clean, maintainable configuration.
