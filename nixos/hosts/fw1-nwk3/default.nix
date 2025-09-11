{inputs, ...}: {
  imports = [
    ./disks.nix
    ../../personalities/server/default.nix
    ../../personalities/server/tailscale.nix
    ../../personalities/base
    inputs.disko.nixosModules.disko
  ];

  # Customize observability for this router
  services.observability = {
    exporters = {
      bind = true;
      frr = false;
    };

    vector.extraLabels = {
      site = "nwk3";
    };
  };

  networking.hostName = "fw1";
  networking.domain = "nwk3.rabbito.tech";
  facter.reportPath = ./facter.json;
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  services.router = {
    enable = true;
    domain = "nwk3.rabbito.tech";

    ipv6 = {
      enable = true;
      enableRadvd = true;
      radvdVlans = [99 100];
    };

    udevRules = ''
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d9", NAME="lan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d8", NAME="wan"
      SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:da", NAME="oob"
    '';

    enableOob = true;
    oobInterface = "oob";
    oobSubnet = "10.10.10.0/24";
    oobAddress = "10.10.10.1";
    enableLan = true;
    lanInterface = "lan";
    lanSubnet = "192.168.1.0/24";
    lanAddress = "192.168.1.1";

    cloudflaredomains = [
      "fw1.nwk3.rabbito.tech"
      "nwk3.rabbito.tech"
    ];

    tailscaleRoutes = [
      "192.168.14.0/24"
      "10.40.99.0/24"
      "192.168.13.0/24"
    ];

    forwardZones = {
      "nwk2.rabbito.tech" = {
        forwarders = ["10.30.99.1"];
      };
      "scr1.rabbito.tech" = {
        forwarders = ["10.20.99.1"];
      };
    };

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
      }
      {
        id = 100;
        name = "endusers";
        subnet = "192.168.14.0/24";
        router = "192.168.14.1";
      }
      {
        id = 101;
        name = "iot";
        subnet = "192.168.13.0/24";
        router = "192.168.13.1";
      }
    ];
  };
}
