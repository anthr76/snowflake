{ inputs, config, pkgs, lib, ... }:
{
 imports = [
   ./default.nix
   ./tailscale.nix
   ../base
 ];
  # Typically enabled in base but since we're a router we want all the control
  networking.networkmanager.enable = lib.mkForce false;
  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
        # TODO: Configure IPV6
        # "net.ipv6.conf.wan.disable_ipv6" = true;
        "net.ipv6.conf.all.accept_ra" = 0;
        "net.ipv6.conf.all.autoconf" = 0;
        "net.ipv6.conf.all.use_tempaddr" = 0;
        "net.ipv6.conf.wan.accept_ra" = 2;
        "net.ipv6.conf.wan.autoconf" = 1;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };
  };
  networking.nat = {
    enable = true;
    internalInterfaces = [
      "vlan8"
      "vlan99"
      "vlan10"
      "vlan100"
      "vlan101"
    ];
    externalInterface = "wan";
  };
  networking.interfaces = {
    wan = {
      useDHCP = true;
    };
    lan = {
      ipv4.addresses = [{
        address = "192.168.1.1";
        prefixLength = 24;
      }];
    };
  };
  networking.vlans = {
    vlan8 = { id=8; interface="lan"; };
    vlan10 = { id=10; interface="lan"; };
    vlan99 = { id=99; interface="lan"; };
    vlan100 = { id=100; interface="lan"; };
    vlan101 = { id=101; interface="lan"; };
  };
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" "vlan8" "vlan10" "vlan99" "vlan100" "vlan101" ];
    interfaces = {
      wan = {
        allowedTCPPorts = [
          22
        ];
        allowedUDPPorts = [
          # Wireguard
          51820
        ];
      };
    };
  };
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      lease-database = {
        name = "/var/lib/kea/dhcp4.leases";
        persist = true;
        type = "memfile";
      };
      rebind-timer = 2000;
      renew-timer = 1000;
      valid-lifetime = 4000;
    };
  };
  services.coredns = {
    enable = true;
    # https://github.com/NixOS/nixpkgs/issues/307750
    package = pkgs.coredns-snowflake;
  };
  services.radvd = {
    enable = true;
    config = ''
      interface vlan100 {
          IgnoreIfMissing on;
          AdvDefaultPreference high;
          MaxRtrAdvInterval 600;
          AdvReachableTime 0;
          AdvIntervalOpt on;
          AdvSendAdvert on;
          AdvOtherConfigFlag off;
          AdvRetransTimer 0;
          AdvCurHopLimit 64;
          prefix ::/0 {
              AdvAutonomous on;
              AdvValidLifetime 2592000;
              AdvOnLink on;
              AdvPreferredLifetime 14400;
              DeprecatePrefix off;
              DecrementLifetimes off;
          };
      };

    '';
  };
}
