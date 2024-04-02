{ pkgs, ... }: {
  imports = [ ../server/tailscale.nix ];
  networking.firewall = { enable = true; };
  networking.wireless.iwd.enable = true;
  # systemd.services.tailscaled = lib.mkForce {
  #   requires = ["tailscaled-ondemand-dispatch.target"];
  #   after = ["tailscaled-ondemand-dispatch.target"];
  #   # This is broken and it hurts :(
  #   wantedBy = ["tailscaled-ondemand-dispatch.target"];
  # };
  system.activationScripts = {
    tailscale.text = ''
      ${pkgs.systemd}/bin/systemctl restart NetworkManager-dispatcher.service
    '';
  };
  systemd.targets.tailscaled-ondemand-dispatch = {
    description = "Ensure's tailscale runs only when it needs to.";
    before = [ "tailscaled.service" ];
    wantedBy = [ "tailscaled.service" ];
    wants = [ "network-online.target" ];
  };
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    dispatcherScripts = [{
      source = pkgs.writeText "hook" ''
        #!/bin/sh
        ${pkgs.systemd}/bin/systemctl stop tailscaled.service
        interface=$1 status=$2
        case $status in
          up)
            logger "tailscaled dispatch: allow dhcp to settle"
            sleep 15
            if [[ "$IP4_DOMAINS" == *"rabbito.tech"* ]]; then
              logger " IP4_DOMAINS ( $IP4_DOMAINS ) has rabbito.tech stopping tailscale"
              systemctl stop tailscaled-ondemand-dispatch.target
            else
              logger "IP4_DOMAINS ( $IP4_DOMAINS ) not rabbito.tech starting tailscale"
              systemctl start tailscaled-ondemand-dispatch.target
            fi
            ;;
          down)
              logger "connection down doing nothing"
            ;;
        esac
      '';
      type = "basic";
    }];
  };

}
