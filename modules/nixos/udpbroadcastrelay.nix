{ config, pkgs, lib, ... }:

{
  options.services.udpbroadcastrelay = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable the UDP Broadcast Relay service.";
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.udpbroadcastrelay;
      description = "The package containing the udpbroadcastrelay.";
    };
    port = lib.mkOption {
      type = lib.types.int;
      example = 5353;
      description = "The UDP port to listen to.";
    };
    id = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Unique ID for the relay instance.";
    };
    interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      example = [ "eth0" "eth1" ];
      description = "List of interfaces to listen on and forward packets to.";
    };
    multicast = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional multicast group to relay.";
    };
    blockCidr = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of CIDRs to block packets from.";
    };
    allowCidr = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of CIDRs to allow packets from.";
    };
    msearch = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "M-SEARCH options for SSDP or similar protocols.";
    };
  };

  config = lib.mkIf config.services.udpbroadcastrelay.enable {
    assertions = lib.mkIf (config.services.udpbroadcastrelay.package == null) [
      {
        assertion = false;
        message = "services.udpbroadcastrelay.package must be set to a valid package containing the udpbroadcastrelay binary.";
      }
    ];

    systemd.services.udpbroadcastrelay = {
      description = "UDP Broadcast Relay Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = ''
          ${config.services.udpbroadcastrelay.package}/bin/udpbroadcastrelay \
          --id ${toString config.services.udpbroadcastrelay.id} \
          --port ${toString config.services.udpbroadcastrelay.port} \
          ${lib.concatStringsSep " " (map (dev: "--dev ${dev}") config.services.udpbroadcastrelay.interfaces)} \
          ${lib.optionalString (config.services.udpbroadcastrelay.multicast != null) "--multicast ${config.services.udpbroadcastrelay.multicast}"} \
          ${lib.concatStringsSep " " (map (cidr: "--blockcidr ${cidr}") config.services.udpbroadcastrelay.blockCidr)} \
          ${lib.concatStringsSep " " (map (cidr: "--allowcidr ${cidr}") config.services.udpbroadcastrelay.allowCidr)} \
          ${lib.concatStringsSep " " (map (m: "--msearch ${m}") config.services.udpbroadcastrelay.msearch)}
        '';
        Restart = "always";
        User = "root";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
