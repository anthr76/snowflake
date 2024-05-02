{ lib, inputs, ... }:
{
  imports = [
    ../../personalities/server/router
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "fw1";
  networking.domain = "nwk2.rabbito.tech";
  services.cfdyndns.records = [
    "fw-1.nwk2.rabbito.tech"
    "nwk2.rabbito.tech"
  ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:27:82:e9", NAME="lan"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:27:82:e8", NAME="wan"
  '';

  networking.interfaces = {
    vlan8 = { ipv4 = { addresses = [{ address = "192.168.15.1"; prefixLength = 24; }]; }; };
    vlan10 = { ipv4 = { addresses = [{ address = "192.168.7.1"; prefixLength = 24; }]; }; };
    vlan99 = { ipv4 = { addresses = [{ address = "10.30.99.1"; prefixLength = 24; }]; }; };
    vlan100 = { ipv4 = { addresses = [{ address = "192.168.11.1"; prefixLength = 24; }]; }; };
    vlan101 = { ipv4 = { addresses = [{ address = "192.168.5.1"; prefixLength = 24; }]; }; };
  };
  services.tailscale.extraUpFlags = [
    "--advertise-routes=192.168.11.0/24,10.30.99.0/24,192.168.7.0/24"
  ];
  services.kea.dhcp4 = {
    settings = {
      interfaces-config = {
        interfaces = [
          "vlan8/192.168.15.1"
          "vlan10/192.168.7.1"
          "vlan99/10.30.99.1"
          "vlan100/192.168.11.1"
          "vlan101/192.168.5.1"
        ];
      };
      option-data = [
        {
          name = "domain-name-servers";
          data = "10.30.99.1";
        }
      ];
      subnet4 = [
        {
          pools = [
            {
              pool = "192.168.15.20 - 192.168.15.240";
            }
          ];
          subnet = "192.168.15.0/24";
          option-data = [
            {
              name = "routers";
              data = "192.168.15.1";
            }
          ];
        }
        {
          pools = [
            {
              pool = "192.168.7.20 - 192.168.7.240";
            }
          ];
          subnet = "192.168.7.0/24";
          option-data = [
            {
              name = "routers";
              data = "192.168.7.1";
            }
          ];
        }
        {
          pools = [
            {
              pool = "10.30.99.20 - 10.30.99.240";
            }
          ];
          subnet = "10.30.99.0/24";
          option-data = [
            {
              name = "routers";
              data = "10.30.99.1";
            }
          ];
        }
        {
          pools = [
            {
              pool = "192.168.11.20 - 192.168.11.240";
            }
          ];
          subnet = "192.168.11.0/24";
          option-data = [
            {
              name = "routers";
              data = "192.168.11.1";
            }
          ];
        }
        {
          pools = [
            {
              pool = "192.168.5.20 - 192.168.5.240";
            }
          ];
          subnet = "192.168.5.0/24";
          option-data = [
            {
              name = "routers";
              data = "192.168.5.1";
            }
          ];
        }
      ];
      valid-lifetime = 4000;
    };
  };
  services.coredns = {
    config = ''
      (common) {
        log error
        reload
        # TODO: Use something like https://github.com/StevenBlack/hosts santized on cron
        loop
        loadbalance
        cache
        local
        prometheus 0.0.0.0:9153
        ready
        hosts {
          fallthrough
          ttl 1
          reload 300ms
        }
      }


      .:53 {
        import common
        forward . tls://1.1.1.1 tls://1.0.0.1 {
          tls_servername cloudflare-dns.com
        }
        health {
          lameduck 5s
        }
      }

      nwk2.rabbito.tech:53 {
        import common
      }
      nwk3.rabbito.tech:53 {
        forward . 10.40.99.1
      }
      scr1.rabbito.tech:53 {
        forward . 10.5.0.7 10.5.0.8
      }
      kutara.io:53 {
        forward . 10.5.0.7 10.5.0.8
      }

    '';
  };
}
