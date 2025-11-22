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
  networking.domain = "qgr1.rabbito.tech";
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod"];
  facter.reportPath = ./facter.json;
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  services.router = {
    enable = true;
    domain = "qgr1.rabbito.tech";
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
      externalDnsZones = ["qgr1.rabbito.tech"];
      defaultTtl = 1;
    };

    fail2ban = {
      enable = true;
      banTime = "12h";
      findTime = "10m";
      maxRetry = 3;
      logLevel = "INFO";

      enabledJails = [
        "sshd"
        "router-scan"
        "router-dns-abuse"
        "router-port-scan"
      ];

      banAction = "iptables-multiport";
    };

    cloudflaredomains = [
      "fw1.qgr1.rabbito.tech"
      "qgr1.rabbito.tech"
    ];
    # TODO: Fixup
    tailscaleRoutes = [
      "192.168.8.0/24" # K8s
      "192.168.4.0/24" # Servers
      "10.20.99.0/24" # Management
      "192.168.6.0/24" # End users
      "10.45.0.0/16" # K8s BGP LoadBalancer IP range
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
            hostname = "master-1";
            mac = "00:1B:21:C1:FD:C6";
            ip = "192.168.8.40";
          }
          {
            hostname = "master-2";
            mac = "80:61:5f:0d:e0:78";
            ip = "192.168.8.47";
          }
          {
            hostname = "master-3";
            mac = "80:61:5f:0d:e2:e2";
            ip = "192.168.8.60";
          }
          {
            hostname = "worker-1";
            mac = "A0:36:9F:FF:FF:FF";
            ip = "192.168.8.20";
          }
          {
            hostname = "worker-2";
            mac = "90:E2:BA:8C:70:3A";
            ip = "192.168.8.62";
          }
          {
            hostname = "worker-3";
            mac = "90:E2:BA:8C:74:98";
            ip = "192.168.8.61";
          }
          {
            hostname = "worker-4";
            mac = "90:E2:BA:44:05:B0";
            ip = "192.168.8.41";
          }
          {
            hostname = "worker-5";
            mac = "80:61:5F:03:99:23";
            ip = "192.168.8.144";
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
        name = "cluster-0-ge";
        type = "A";
        value = "10.45.0.43";
      }
    ];
  };

  # BGP daemon for K8s BGP support
  services.bgp = {
    enable = true;
    routerId = "192.168.8.1";
    localASN = 64513;
    peerGroupName = "k8s";
    peerASN = 64512;
    nextHopSelf = true;

    # BGP peers - K8s BGP speakers on worker nodes
    peers = [
      {
        address = "192.168.8.20";
        description = "K8s BGP speaker on worker-1";
      }
      {
        address = "192.168.8.62";
        description = "K8s BGP speaker on worker-2";
      }
      {
        address = "192.168.8.61";
        description = "K8s BGP speaker on worker-3";
      }
      {
        address = "192.168.8.41";
        description = "K8s BGP speaker on worker-4";
      }
      {
        address = "192.168.8.144";
        description = "K8s BGP speaker on worker-5";
      }
    ];

    logLevel = "informational";
  };
}
