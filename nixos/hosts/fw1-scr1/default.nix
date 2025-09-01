{
  lib,
  inputs,
  config,
  ...
}: {
  imports = [
    ../../personalities/server/default.nix
    ../../personalities/server/tailscale.nix
    ../../personalities/base
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "fw1";
  networking.domain = "scr1.rabbito.tech";
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.router = {
    enable = true;
    domain = "scr1.rabbito.tech";
    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d5", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d0", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="20:7c:14:f8:4a:d1", NAME="oob"
    '';
    enableLan = true;
    lanInterface = "lan";
    lanSubnet = "192.168.1.0/24";
    lanAddress = "192.168.1.1";
    enableOob = true;
    oobInterface = "oob";
    oobSubnet = "10.10.10.0/24";
    oobAddress = "10.10.10.1";

    # RFC 2136 / external-dns support
    rfc2136 = {
      enable = true;
      externalDnsZones = ["scr1.rabbito.tech" "kutara.io"];
      defaultTtl = 1;
    };

    cloudflaredomains = [
      "fw1.scr1.rabbito.tech"
      "scr1.rabbito.tech"
      "cluster-0.scr1.rabbito.tech"
    ];
    # TODO: Fixup
    tailscaleRoutes = [
      "192.168.8.0/24" # K8s
      "192.168.4.0/24" # Servers
      "10.20.99.0/24" # Management
      "192.168.6.0/24" # End users
      "10.45.0.0/16" # MetalLB LoadBalancer IP range
    ];

    forwardZones = {
      "nwk3.rabbito.tech" = {
        forwarders = ["10.40.99.1"];
      };
      "nwk2.rabbito.tech" = {
        forwarders = ["10.30.99.1"];
      };
    };

    # Standard VLAN configuration
    vlans = [
      {
        id = 8;
        name = "kubernetes";
        subnet = "192.168.8.0/24";
        router = "192.168.8.1";
        enabled = true;
        staticReservations = [
          {
            hostname = "master-01";
            mac = "00:1B:21:C1:FD:C6";
            ip = "192.168.8.40";
          }
          {
            hostname = "master-02";
            mac = "80:61:5f:0d:e0:78";
            ip = "192.168.8.47";
          }
          {
            hostname = "master-03";
            mac = "80:61:5f:0d:e2:e2";
            ip = "192.168.8.60";
          }
        ];
      }
      {
        id = 10;
        name = "servers";
        subnet = "192.168.4.0/24";
        router = "192.168.4.1";
      }
      {
        id = 99;
        name = "management";
        subnet = "10.20.99.0/24";
        router = "10.20.99.1";
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.6.0/24";
        router = "192.168.6.1";
      }
      {
        id = 101;
        name = "guests";
        subnet = "192.168.12.0/24";
        router = "192.168.12.1";
      }
    ];

    dnsRecords = [
      {
        name = "master-01";
        type = "A";
        value = "192.168.8.40";
      }
      {
        name = "master-02";
        type = "A";
        value = "192.168.8.47";
      }
      {
        name = "master-03";
        type = "A";
        value = "192.168.8.60";
      }
      {
        name = "cluster-0";
        type = "A";
        value = "192.168.8.1";
      }
      {
        name = "cluster-0-ie";
        type = "A";
        value = "10.45.0.80";
      }
    ];
  };

  # HAProxy for Kubernetes control-plane load balancing
  services.haproxy-k8s = {
    enable = true;
    frontendPort = 6443;
    bindAddress = "192.168.8.1"; # Router IP on kubernetes VLAN
    controlPlaneNodes = [
      {
        name = "master-01";
        address = "192.168.8.40";
        port = 6443;
      }
      {
        name = "master-02";
        address = "192.168.8.47";
        port = 6443;
      }
      {
        name = "master-03";
        address = "192.168.8.60";
        port = 6443;
      }
    ];
  };

  # BGP daemon for MetalLB support
  services.bgp = {
    enable = true;
    routerId = "192.168.8.1";
    localASN = 64512;

    # Advertise the MetalLB IP pool
    networks = [
      {
        network = "10.45.0.0/16";
        description = "MetalLB LoadBalancer IP range";
      }
    ];

    # BGP peers - MetalLB speakers on all Kubernetes nodes
    peers = [
      # Control plane nodes (masters)
      {
        address = "192.168.8.40";
        asn = 64512;
        description = "MetalLB speaker on master-01";
      }
      {
        address = "192.168.8.47";
        asn = 64512;
        description = "MetalLB speaker on master-02";
      }
      {
        address = "192.168.8.60";
        asn = 64512;
        description = "MetalLB speaker on master-03";
      }
      # Worker nodes
      {
        address = "192.168.8.20";
        asn = 64512;
        description = "MetalLB speaker on worker-01";
      }
      {
        address = "192.168.8.62";
        asn = 64512;
        description = "MetalLB speaker on worker-02";
      }
      {
        address = "192.168.8.61";
        asn = 64512;
        description = "MetalLB speaker on worker-03";
      }
      {
        address = "192.168.8.41";
        asn = 64512;
        description = "MetalLB speaker on worker-13";
      }
      {
        address = "192.168.8.144";
        asn = 64512;
        description = "MetalLB speaker on worker-14";
      }
    ];

    interface = "lan";
    logLevel = "informational";

    # Additional BGP configuration if needed
    extraConfig = ''
      ! Additional MetalLB specific configuration
      ! Ensure faster convergence for load balancer IPs
      ! Control plane nodes
      neighbor 192.168.8.40 timers 30 90
      neighbor 192.168.8.47 timers 30 90
      neighbor 192.168.8.60 timers 30 90
      ! Worker nodes
      neighbor 192.168.8.20 timers 30 90
      neighbor 192.168.8.62 timers 30 90
      neighbor 192.168.8.61 timers 30 90
      neighbor 192.168.8.41 timers 30 90
      neighbor 192.168.8.144 timers 30 90
    '';
  };
}
