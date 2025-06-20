{
  lib,
  inputs,
  pkgs,
  config,
  ...
}:
let
  zoneSerial = toString inputs.self.lastModified;
in
{
  imports = [
    ../../personalities/server/router
    ./disks.nix
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "fw1";
  networking.domain = "nwk3.rabbito.tech";
  services.cloudflare-dyndns.domains = [
    "fw-1.nwk3.rabbito.tech"
    "nwk3.rabbito.tech"
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
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d9", NAME="lan"
    SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="00:e0:67:26:40:d8", NAME="wan"
  '';

  networking.interfaces = {
    lan = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.1.1";
            prefixLength = 24;
          }
        ];
      };
    };
    vlan8 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.17.1";
            prefixLength = 24;
          }
        ];
      };
    };
    vlan10 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.16.1";
            prefixLength = 24;
          }
        ];
      };
    };
    vlan99 = {
      ipv4 = {
        addresses = [
          {
            address = "10.40.99.1";
            prefixLength = 24;
          }
        ];
      };
    };
    vlan100 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.14.1";
            prefixLength = 24;
          }
        ];
      };
    };
    vlan101 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.13.1";
            prefixLength = 24;
          }
        ];
      };
    };
  };
  services.tailscale.extraUpFlags = [
    "--advertise-routes=192.168.14.0/24,10.40.99.0/24,192.168.13.0/24"
  ];
  services.kea.dhcp4 = {
    settings = {
      interfaces-config = {
        interfaces = [
          "lan/192.168.1.1"
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
        {
          name = "domain-search";
          data = "nwk3.rabbito.tech,mole-bowfin.ts.net";
        }
      ];
      subnet4 = [
        {
          subnet = "192.168.1.0/24";
          id = 1;
          pools = [
            { pool = "192.168.1.20 - 192.168.1.240"; }
          ];
          option-data = [
            { name = "routers"; data = "192.168.1.1"; }
          ];
          client-class = "ubnt"; # Only apply vendor option to this subnet
        }
        {
          subnet = "192.168.17.0/24";
          id = 17;
          pools = [
            { pool = "192.168.17.20 - 192.168.17.240"; }
          ];
          option-data = [
            { name = "routers"; data = "192.168.17.1"; }
          ];
        }
        {
          subnet = "192.168.16.0/24";
          id = 16;
          pools = [
            { pool = "192.168.16.20 - 192.168.16.240"; }
          ];
          option-data = [
            { name = "routers"; data = "192.168.16.1"; }
          ];
        }
        {
          subnet = "10.40.99.0/24";
          id = 99;
          pools = [
            { pool = "10.40.99.20 - 10.40.99.240"; }
          ];
          option-data = [
            { name = "routers"; data = "10.40.99.1"; }
          ];
          client-class = "ubnt"; # Only apply vendor option to this subnet
        }
        {
          subnet = "192.168.14.0/24";
          id = 14;
          pools = [
            { pool = "192.168.14.20 - 192.168.14.240"; }
          ];
          option-data = [
            { name = "routers"; data = "192.168.14.1"; }
          ];
        }
        {
          subnet = "192.168.13.0/24";
          id = 13;
          pools = [
            { pool = "192.168.13.20 - 192.168.13.240"; }
          ];
          option-data = [
            { name = "routers"; data = "192.168.13.1"; }
          ];
        }
      ];
      client-classes = [
        {
          name = "ubnt";
          test = "substring(option[60].text, 0, 4) == 'ubnt'";
          option-data = [
            {
              name = "vendor-encapsulated-options";
              csv-format = false;
              data = "01040a2d0006"; # Option 1 (Unifi IP): 10.45.0.6
            }
          ];
        }
      ];
      valid-lifetime = 4000;
    };
  };
  services.bind = {
    extraConfig = ''
      zone "mole-bowfin.ts.net" {
          type forward;
          forwarders { 100.100.100.100; };
      };
      zone "scr1.rabbito.tech" {
          type forward;
          forwarders { 10.5.0.7; 10.5.0.8; };
      };
      zone "kutara.io" {
          type forward;
          forwarders { 10.5.0.7; 10.5.0.8; };
      };
      zone "nwk2.rabbito.tech" {
          type forward;
          forwarders { 10.30.99.1; };
      };
    '';
    zones = {
      "nwk3.rabbito.tech." = {
        master = true;
        extraConfig = ''
           allow-update { key "dhcp-update-key"; };
           journal "${config.services.bind.directory}/db.nwk3.rabbito.tech.jnl";
        '';
        file = pkgs.writeText "nwk3.rabbito.tech" (
          lib.strings.concatStrings [
            ''
              $ORIGIN nwk3.rabbito.tech.
              $TTL    86400
              @ IN SOA nwk3.rabbito.tech. admin.rabbito.tech (
              ${zoneSerial}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      fw1.nwk3.rabbito.tech.
              fw1             IN    A       10.40.99.1
              unifi           IN    CNAME   unifi.scr1.rabbito.tech.
            ''
          ]
        );
      };
      "14.168.192.in-addr.arpa." = {
        master = true;
        extraConfig = ''
           allow-update { key "dhcp-update-key"; };
           journal "${config.services.bind.directory}/db.14.168.192.in-addr.arpa.jnl";
        '';
        file = pkgs.writeText "14.168.192.in-addr.arpa" (
          lib.strings.concatStrings [
            ''
              $ORIGIN 14.168.192.in-addr.arpa.
              $TTL    86400
              @ IN SOA nwk3.rabbito.tech. admin.rabbito.tech (
              ${zoneSerial}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      fw1.nwk3.rabbito.tech.
            ''
          ]
        );
      };
      "13.168.192.in-addr.arpa." = {
        master = true;
        extraConfig = ''
           allow-update { key "dhcp-update-key"; };
           journal "${config.services.bind.directory}/db.13.168.192.in-addr.arpa.jnl";
        '';
        file = pkgs.writeText "13.168.192.in-addr.arpa" (
          lib.strings.concatStrings [
            ''
              $ORIGIN 13.168.192.in-addr.arpa.
              $TTL    86400
              @ IN SOA nwk3.rabbito.tech. admin.rabbito.tech (
              ${zoneSerial}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      fw1.nwk3.rabbito.tech.
            ''
          ]
        );
      };
      "16.168.192.in-addr.arpa." = {
        master = true;
        extraConfig = ''
           allow-update { key "dhcp-update-key"; };
           journal "${config.services.bind.directory}/db.16.168.192.in-addr.arpa.jnl";
        '';
        file = pkgs.writeText "16.168.192.in-addr.arpa" (
          lib.strings.concatStrings [
            ''
              $ORIGIN 16.168.192.in-addr.arpa.
              $TTL    86400
              @ IN SOA nwk3.rabbito.tech. admin.rabbito.tech (
              ${zoneSerial}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      fw1.nwk3.rabbito.tech.
            ''
          ]
        );
      };
      "99.40.10.in-addr.arpa." = {
        master = true;
        extraConfig = ''
           allow-update { key "dhcp-update-key"; };
           journal "${config.services.bind.directory}/db.99.40.10.in-addr.arpa.jnl";
        '';
        file = pkgs.writeText "99.40.10.in-addr.arpa" (
          lib.strings.concatStrings [
            ''
              $ORIGIN 99.40.10.in-addr.arpa.
              $TTL    86400
              @ IN SOA nwk3.rabbito.tech. admin.rabbito.tech (
              ${zoneSerial}           ; serial number
              3600                    ; refresh
              900                     ; retry
              1209600                 ; expire
              1800                    ; ttl
              )
                              IN    NS      fw1.nwk3.rabbito.tech.
              1               IN    PTR     fw1.nwk3.rabbito.tech.
            ''
          ]
        );
      };
    };
  };
  services.kea.dhcp-ddns = {
    settings = {
      reverse-ddns = {
        ddns-domains = [
          {
            name = "14.168.192.in-addr.arpa.";
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = "10.40.99.1";
              port = 53;
            }];
          }
          {
            name = "13.168.192.in-addr.arpa.";
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = "10.40.99.1";
              port = 53;
            }];
          }
          {
            name = "16.168.192.in-addr.arpa.";
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = "10.40.99.1";
              port = 53;
            }];
          }
          {
            name = "99.40.10.in-addr.arpa";
            key-name = "dhcp-update-key";
            dns-servers = [{
              hostname = "";
              ip-address = "10.40.99.1";
              port = 53;
            }];
          }
        ];
      };
    };
  };
}
