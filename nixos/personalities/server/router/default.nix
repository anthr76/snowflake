{ inputs, config, pkgs, lib, ... }:
{
 imports = [
   ../default.nix
   ../tailscale.nix
   ../../base
   ./ddns.nix
   ./dhcp.nix
   ./dns.nix
   ./firewall.nix
 ];
  # Typically enabled in base but since we're a router we want all the control
  networking.networkmanager.enable = lib.mkForce false;
  environment.systemPackages = with pkgs; [
    ethtool
    tcpdump
    conntrack-tools
    mtr
    nmap
  ];
  boot = {
    kernel = {
      sysctl = {
        "net.ipv4.conf.all.forwarding" = true;
        "net.ipv6.conf.all.forwarding" = true;
        # TODO: Configure IPV6
        "net.ipv6.conf.wan.disable_ipv6" = true;
        # "net.ipv6.conf.all.accept_ra" = 0;
        # "net.ipv6.conf.all.autoconf" = 0;
        # "net.ipv6.conf.all.use_tempaddr" = 0;
        # "net.ipv6.conf.wan.accept_ra" = 2;
        # "net.ipv6.conf.wan.autoconf" = 1;
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
  services.avahi = {
    enable = true;
    hostName = "${config.networking.hostName}";
    allowInterfaces = [ "vlan100" "vlan101" ];
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      userServices = true;
    };
  };
  services.udpbroadcastrelay = {
    enable = true;
    package = pkgs.udpbroadcastrelay;
    port = 5353;
    id = 2;
    interfaces = [ "vlan101" "vlan100" ];
    multicast = "224.0.0.251";
  };
  services.miniupnpd = {
    enable = true;
    upnp = false;
    natpmp = true;
    externalInterface = "wan";
    internalIPs = [
      "vlan10"
      "vlan100"
      "vlan101"
      "vlan8"
      "vlan99"
      "lan"
    ];
  };
}
