{ lib, inputs, ... }:
{
  imports = [
    ../../personalities/server/router.nix
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "fw1";
  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  services.udev.extraRules = ''
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d9", NAME="lan"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d8", NAME="wan"
  '';

  networking.interfaces = {
    vlan8 = { ipv4 = { addresses = [{ address = "192.168.17.1"; prefixLength = 24; }]; }; };
    vlan10 = { ipv4 = { addresses = [{ address = "192.168.16.1"; prefixLength = 24; }]; }; };
    vlan99 = { ipv4 = { addresses = [{ address = "10.40.99.1"; prefixLength = 24; }]; }; };
    vlan100 = { ipv4 = { addresses = [{ address = "192.168.14.1"; prefixLength = 24; }]; }; };
    vlan101 = { ipv4 = { addresses = [{ address = "192.168.13.1"; prefixLength = 24; }]; }; };
  };
  services.kea.dhcp4 = {
    settings = {
      interfaces-config = {
        interfaces = [
          "vlan8/192.168.17.1"
          "vlan10/192.168.16.1"
          "vlan99/10.40.99.1"
          "vlan100/192.168.14.1"
          "vlan101/192.168.13.1"
        ];
      };
      option-data = [
        {
          name = "domain-name-servers";
          data = "10.40.99.1";
        }
      ];
      subnet4 = [
        {
          pools = [
            {
              pool = "192.168.17 - 192.168.17.240";
            }
          ];
          subnet = "192.168.17.0/24";
        }
        {
          pools = [
            {
              pool = "192.168.16.100 - 192.168.16.240";
            }
          ];
          subnet = "192.168.16.0/24";
        }
        {
          pools = [
            {
              pool = "10.49.99.100 - 10.49.99.240";
            }
          ];
          subnet = "10.49.99.0/24";
        }
        {
          pools = [
            {
              pool = "192.168.14.100 - 192.168.14.240";
            }
          ];
          subnet = "192.168.14.0/24";
        }
        {
          pools = [
            {
              pool = "192.168.13.100 - 192.168.13.240";
            }
          ];
          subnet = "192.168.13.0/24";
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
        template ANY ANY {
          match (?:^|\.)(?:deviceenrollment|mdmenrollment|iprofiles|wifi)?\.(?:.{1,3})+
          rcode NXDOMAIN
          fallthrough
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

      nwk3.rabbito.tech:53 {
        import common
      }
      nwk2.rabbito.tech:53 {
        forward . 10.6.0.7 10.6.0.8
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
