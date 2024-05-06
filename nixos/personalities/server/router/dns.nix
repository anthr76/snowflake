{ config, outputs, pkgs, ... }:
{
  systemd.timers.dnscrypt-proxy2-blocklists = {
    description = "Fetch and update blocklist file daily";
    wantedBy = [ "timers.target" "dnscrypt-proxy2.service"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
  systemd.services.dnscrypt-proxy2-blocklists = {
    path = [
      pkgs.curl
    ];
    script = ''
      set -x
      curl -o /var/lib/dnscrypt-proxy/blocklist.txt https://big.oisd.nl/domainswild
    '';
    serviceConfig.Type = "oneshot";
    serviceConfig.Restart = "on-failure";
  };
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:53" ];
      blocked_names = {
        blocked_names_file = "/var/lib/dnscrypt-proxy/blocklist.txt";
      };
    };
  };
  services.bind = {
    enable = true;
    forward = "only";
    forwarders = [
      "127.0.0.1"
    ];
    listenOn = [
      # Parsed Example
      # 192.168.1.1
      (builtins.elemAt config.networking.interfaces."vlan99".ipv4.addresses 0).address
    ];
    # TODO: nix repl this.
    # Parsed Example 192.168.1.0/24
    cacheNetworks = [
      # Vlan 8,10,99,100,101 NWK2
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk3.config.services.kea.dhcp4.settings.subnet4 0).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk3.config.services.kea.dhcp4.settings.subnet4 1).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk3.config.services.kea.dhcp4.settings.subnet4 2).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk3.config.services.kea.dhcp4.settings.subnet4 3).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk3.config.services.kea.dhcp4.settings.subnet4 4).subnet
      # Vlan 8,10,99,100,101 NWK2
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk2.config.services.kea.dhcp4.settings.subnet4 0).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk2.config.services.kea.dhcp4.settings.subnet4 1).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk2.config.services.kea.dhcp4.settings.subnet4 2).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk2.config.services.kea.dhcp4.settings.subnet4 3).subnet
      (builtins.elemAt outputs.nixosConfigurations.fw1-nwk2.config.services.kea.dhcp4.settings.subnet4 4).subnet
      # Temp SCR1 / QGR
      "192.168.12.0/24"
      "192.168.6.0/24"
      "192.168.4.0/24"
      "10.20.99.0/24"
      "10.5.0.0/24"

    ];
    extraOptions = ''
      dnssec-validation no;
    '';
  };
}
