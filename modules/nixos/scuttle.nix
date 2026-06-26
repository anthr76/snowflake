{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.scuttle;
in {
  options.services.scuttle = {
    enable = mkEnableOption "scuttle - Kubelet graceful node drain/delete and spot termination watcher";

    package = mkOption {
      type = types.package;
      default = pkgs.scuttle;
      defaultText = literalExpression "pkgs.scuttle";
      description = "The scuttle package to use.";
    };

    nodeName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      defaultText = literalExpression "config.networking.hostName";
      description = "Kubernetes node name";
    };

    platform = mkOption {
      type = types.nullOr (types.enum ["aws" "azure"]);
      default = null;
      description = "Platform to poll for termination notices (aws or azure)";
    };

    uncordon = mkOption {
      type = types.bool;
      default = true;
      description = "Uncordon node on start";
    };

    drain = mkOption {
      type = types.bool;
      default = true;
      description = "Drain node on stop";
    };

    delete = mkOption {
      type = types.bool;
      default = true;
      description = "Delete node on stop";
    };

    kubeconfigPath = mkOption {
      type = types.str;
      default = "/var/lib/kubelet/kubeconfig";
      description = "Path to kubeconfig file";
    };

    slack = {
      channelId = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Slack Channel ID";
      };

      tokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Slack Bot Token";
      };

      webhookFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to file containing Slack Webhook URL";
      };
    };

    logLevel = mkOption {
      type = types.enum ["debug" "info" "warn" "error"];
      default = "info";
      description = "Logger level";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra command-line arguments to pass to scuttle";
    };

    kubeletService = mkOption {
      type = types.str;
      default = "kubelet.service";
      description = "Name of the kubelet systemd service to bind to";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.scuttle = {
      description = "Scuttle Kubelet before Shutdown";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target" cfg.kubeletService "network-online.target"];
      bindsTo = [cfg.kubeletService];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        TimeoutStopSec = 180;
        SuccessExitStatus = [0 143];
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..60}; do [ -f ${cfg.kubeconfigPath} ] && exit 0; echo \"Waiting for ${cfg.kubeconfigPath} ($i/60)\"; sleep 5; done; echo \"ERROR: ${cfg.kubeconfigPath} not found after 5 minutes\"; exit 1'";
      };

      path = [cfg.package];

      environment = {
        KUBECONFIG = cfg.kubeconfigPath;
        HOSTNAME = cfg.nodeName;
      };

      script = let
        args =
          [
            "-uncordon=${boolToString cfg.uncordon}"
            "-drain=${boolToString cfg.drain}"
            "-delete=${boolToString cfg.delete}"
            "-log-level=${cfg.logLevel}"
          ]
          ++ optional (cfg.platform != null) "-platform=${cfg.platform}"
          ++ optional (cfg.slack.channelId != null) "-channel-id=${cfg.slack.channelId}"
          ++ cfg.extraArgs;

        tokenArg = optionalString (cfg.slack.tokenFile != null) ''-token="$(cat ${cfg.slack.tokenFile})"'';
        webhookArg = optionalString (cfg.slack.webhookFile != null) ''-webhook="$(cat ${cfg.slack.webhookFile})"'';
      in ''
        exec ${cfg.package}/bin/scuttle \
          ${concatStringsSep " \\\n  " args} \
          ${tokenArg} \
          ${webhookArg}
      '';
    };
  };
}
