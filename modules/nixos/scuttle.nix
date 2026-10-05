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

    clearPodsOnDelete = mkOption {
      type = types.bool;
      default = false;
      description = ''
        After scuttle stops, remove every remaining CRI pod sandbox on the host
        if the Node object it was running under no longer exists (deleted, or
        re-registered with a new UID).

        A drain leaves DaemonSet pods running. When the Node is deleted and
        re-registered it is handed a new podCIDR, but a CNI agent that kept
        running still uses the old one. Clearing the sandboxes makes the agent
        and every other leftover pod start fresh against the new Node.
      '';
    };

    criSocket = mkOption {
      type = types.str;
      default = "unix:///run/containerd/containerd.sock";
      description = "CRI runtime endpoint used by clearPodsOnDelete";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.scuttle = let
      kubectl = "${pkgs.kubectl}/bin/kubectl --kubeconfig ${cfg.kubeconfigPath} --request-timeout=10s";
      crictl = "${pkgs.cri-tools}/bin/crictl --runtime-endpoint ${cfg.criSocket}";
      uidFile = "/run/scuttle/node-uid";

      # Remember which Node object this boot of scuttle is guarding.
      recordNodeUid = pkgs.writeShellScript "scuttle-record-node-uid" ''
        for i in $(seq 1 24); do
          uid="$(${kubectl} get node ${cfg.nodeName} -o jsonpath='{.metadata.uid}' 2>/dev/null)"
          if [ -n "$uid" ]; then
            echo "$uid" > ${uidFile}
            echo "Recorded Node ${cfg.nodeName} uid $uid"
            exit 0
          fi
          sleep 5
        done
        echo "Node ${cfg.nodeName} not found after 2 minutes; not recording a uid"
        rm -f ${uidFile}
      '';

      # Only clear pods when we can prove the Node object was replaced or
      # removed. Any doubt (no recorded uid, API unreachable) leaves pods alone.
      clearPods = pkgs.writeShellScript "scuttle-clear-pods" ''
        old="$(cat ${uidFile} 2>/dev/null)"
        rm -f ${uidFile}
        if [ -z "$old" ]; then
          echo "No recorded Node uid; leaving pods alone"
          exit 0
        fi

        if new="$(${kubectl} get node ${cfg.nodeName} -o jsonpath='{.metadata.uid}' 2>&1)"; then
          if [ "$new" = "$old" ]; then
            echo "Node ${cfg.nodeName} unchanged; leaving pods alone"
            exit 0
          fi
          echo "Node ${cfg.nodeName} was re-registered ($old -> $new)"
        elif echo "$new" | grep -q "NotFound"; then
          echo "Node ${cfg.nodeName} was deleted"
        else
          echo "Could not read Node ${cfg.nodeName}; leaving pods alone: $new"
          exit 0
        fi

        echo "Stopping remaining containers"
        ${crictl} ps -q | xargs -r -P 16 -n 1 ${crictl} stop --timeout 30 || true
        echo "Removing remaining pod sandboxes"
        ${crictl} rmp -fa || true
      '';
    in {
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
      } // optionalAttrs cfg.clearPodsOnDelete {
        RuntimeDirectory = "scuttle";
        RuntimeDirectoryPreserve = "yes";
        ExecStopPost = "-${clearPods}";
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
        ${optionalString cfg.clearPodsOnDelete "${recordNodeUid} &"}
        exec ${cfg.package}/bin/scuttle \
          ${concatStringsSep " \\\n  " args} \
          ${tokenArg} \
          ${webhookArg}
      '';
    };
  };
}
