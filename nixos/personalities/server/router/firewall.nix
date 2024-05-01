{
    networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" "vlan8" "vlan10" "vlan99" "vlan100" "vlan101" ];
    interfaces = {
      wan = {
        allowedTCPPorts = [
          22
        ];
        allowedUDPPorts = [
        ];
      };
    };
  };
}
