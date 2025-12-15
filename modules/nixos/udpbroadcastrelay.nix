{
  config,
  pkgs,
  lib,
  ...
}: {
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
      example = ["eth0" "eth1"];
      description = "List of interfaces to listen on and forward packets to.";
    };
    multicast = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional multicast group to relay (deprecated, use multicastAddresses).";
    };
    multicastAddresses = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["239.255.255.250" "ff02::c"];
      description = "List of multicast addresses to relay (supports both IPv4 and IPv6).";
    };
    debug = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable debug output (adds -d flag, use twice for verbose with -d -d).";
    };
    debugLevel = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Debug level: 1 for normal debug, 2 for verbose debug.";
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
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open firewall ports for multicast relay (IGMP + configured UDP port/multicast)";
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
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        ExecStart = let
          cfg = config.services.udpbroadcastrelay;
          # Combine old multicast option with new multicastAddresses list
          allMulticastAddrs =
            lib.optionals (cfg.multicast != null) [cfg.multicast]
            ++ cfg.multicastAddresses;
          debugFlags =
            lib.optionalString cfg.debug
            (lib.concatStrings (lib.replicate cfg.debugLevel "-d "));
        in ''
          ${cfg.package}/bin/udpbroadcastrelay \
          --id ${toString cfg.id} \
          --port ${toString cfg.port} \
          ${lib.concatStringsSep " " (map (dev: "--dev ${dev}") cfg.interfaces)} \
          ${lib.concatStringsSep " " (map (addr: "--multicast ${addr}") allMulticastAddrs)} \
          ${lib.concatStringsSep " " (map (cidr: "--blockcidr ${cidr}") cfg.blockCidr)} \
          ${lib.concatStringsSep " " (map (cidr: "--allowcidr ${cidr}") cfg.allowCidr)} \
          ${lib.concatStringsSep " " (map (m: "--msearch ${m}") cfg.msearch)} \
          ${debugFlags}
        '';
        Restart = "always";
        User = "root";
      };
      wantedBy = ["multi-user.target"];
    };

    # Firewall rules for multicast relay
    networking.firewall.extraCommands = lib.mkIf config.services.udpbroadcastrelay.openFirewall (
      let
        cfg = config.services.udpbroadcastrelay;
        allMulticastAddrs =
          lib.optionals (cfg.multicast != null) [cfg.multicast]
          ++ cfg.multicastAddresses;

        # Detect if an address is IPv6
        isIPv6 = addr: lib.hasInfix ":" addr;

        # Generate firewall rules for each multicast address
        mkMulticastRules = addr:
          if isIPv6 addr
          then ''
            # IPv6 multicast traffic for ${addr}
            ip6tables -A INPUT -p udp -d ${addr} --dport ${toString cfg.port} -j ACCEPT
            ip6tables -A FORWARD -p udp -d ${addr} --dport ${toString cfg.port} -j ACCEPT
          ''
          else ''
            # IPv4 multicast traffic for ${addr}
            iptables -A INPUT -p udp -d ${addr} --dport ${toString cfg.port} -j ACCEPT
            iptables -A FORWARD -p udp -d ${addr} --dport ${toString cfg.port} -j ACCEPT
          '';
      in ''
        # IGMP for IPv4 multicast group management
        iptables -A INPUT -p igmp -j ACCEPT
        iptables -A FORWARD -p igmp -j ACCEPT

        # ICMPv6 for IPv6 multicast (MLD - Multicast Listener Discovery)
        ip6tables -A INPUT -p ipv6-icmp -j ACCEPT
        ip6tables -A FORWARD -p ipv6-icmp -j ACCEPT

        ${lib.concatMapStrings mkMulticastRules allMulticastAddrs}
      ''
    );
  };
}
