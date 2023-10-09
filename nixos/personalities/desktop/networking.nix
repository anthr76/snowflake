{pkgs, ...}:
{
    imports = [
    ../server/tailscale.nix
    ];
    networking.firewall = {
      enable = true;
    };
    systemd.services.tailscaled.requires = ["tailscale-ondemand-dispatch.target"];
    systemd.targets.tailscale-ondemand-dispatch = {
        description = "Ensure's tailscale runs only when it needs to.";
    };
    networking.networkmanager = {
        enable = true;
        dispatcherScripts = [
          {
            source = pkgs.writeText "hook" ''
            #!/bin/sh
            interface=$1 status=$2
            case $status in
              up)
                logger "allow dhcp to settle"
                sleep 15
                if [[ "$IP4_DOMAINS" == *"rabbito.tech"* ]]; then
                  logger " IP4_DOMAINS ( $IP4_DOMAINS ) rabbito.tech stopping tailscale"
                  systemctl stop tailscale-ondemand-dispatch.target
                else
                  logger "IP4_DOMAINS ( $IP4_DOMAINS ) not rabbito.tech starting tailscale"
                  systemctl start tailscale-ondemand-dispatch.target
                fi
                ;;
              down)
                  logger "connection down doing nothing"
                ;;
            esac
            '';
            type = "basic";
          }
        ];
    };

}
