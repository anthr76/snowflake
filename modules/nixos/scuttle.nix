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

    drainTimeout = mkOption {
      type = types.ints.unsigned;
      default = 600;
      description = ''
        Seconds to keep retrying evictions blocked by PodDisruptionBudgets and
        waiting for evicted pods to terminate before deleting the Node anyway.
        0 keeps upstream's single eviction pass. The unit's stop timeout is
        derived from this.
      '';
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
        After kubelet stops, remove every remaining CRI pod sandbox on the host
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

    criService = mkOption {
      type = types.str;
      default = "containerd.service";
      description = ''
        systemd unit serving criSocket. With clearPodsOnDelete, the
        scuttle-clear-pods unit is ordered after it so that, when both stop in
        one transaction (e.g. a nixos-rebuild switch that changes containerd),
        the runtime is still up while leftover pods are cleared.
      '';
    };
  };

  config = mkIf cfg.enable (let
      kubectl = "${pkgs.kubectl}/bin/kubectl --kubeconfig ${cfg.kubeconfigPath} --request-timeout=10s";
      # --timeout is crictl's per-RPC deadline (default 2s). StopContainer with a
      # 30s grace period, and StopPodSandbox/RemovePodSandbox on a busy node,
      # need far longer or they fail with DeadlineExceeded.
      crictl = "${pkgs.cri-tools}/bin/crictl --runtime-endpoint ${cfg.criSocket} --timeout 60s";
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

        # The runtime must be reachable, otherwise nothing gets cleared and
        # the leftover pods keep their old addresses. Fail loudly instead.
        for i in $(seq 1 15); do
          ${crictl} info >/dev/null 2>&1 && break
          if [ "$i" = 15 ]; then
            echo "ERROR: CRI runtime at ${cfg.criSocket} unreachable; leftover pods were NOT cleared"
            exit 1
          fi
          sleep 2
        done

        echo "Stopping remaining containers"
        ${crictl} ps -q | xargs -r -P 16 -n 1 ${crictl} stop --timeout 30 || true

        # kubelet is already stopped here, so nothing recreates sandboxes and
        # any that remain after a few passes are a real failure.
        for pass in 1 2 3; do
          pods="$(${crictl} pods -q)"
          [ -z "$pods" ] && break
          echo "Removing $(echo "$pods" | wc -l) pod sandboxes (pass $pass)"
          echo "$pods" | xargs -r -P 16 -n 1 ${crictl} stopp || true
          echo "$pods" | xargs -r -P 16 -n 1 ${crictl} rmp -f || true
        done

        left="$(${crictl} pods -q | wc -l)"
        if [ "$left" -ne 0 ]; then
          echo "ERROR: $left pod sandboxes remain after clearing"
          exit 1
        fi
        echo "All pod sandboxes removed"
      '';
    in {
    # Runs clearPods after kubelet has stopped and before the CRI runtime
    # stops. Stop order is the reverse of start order, so with scuttle
    # After=kubelet and this unit Before=kubelet, After=criService, a kubelet
    # stop (restart, switch, shutdown) goes: scuttle (drain, delete Node) ->
    # kubelet -> scuttle-clear-pods -> containerd.
    systemd.services.scuttle-clear-pods = mkIf cfg.clearPodsOnDelete {
      description = "Clear leftover pods after scuttle deletes the Node";
      wantedBy = ["multi-user.target" cfg.kubeletService];
      partOf = [cfg.kubeletService];
      before = [cfg.kubeletService];
      # The clear asks the API server whether the Node was deleted. Ordering
      # after the network (and DNS) means that on shutdown it stops while they
      # are still up; otherwise the lookup can fail and pods are left alone.
      after = [cfg.criService "network-online.target" "nss-lookup.target"];
      wants = ["network-online.target"];
      restartIfChanged = false;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = "${clearPods}";
        TimeoutStopSec = 300;
      };
    };

    systemd.services.scuttle = {
      description = "Scuttle Kubelet before Shutdown";
      # Stopping scuttle drains and deletes the Node. kubelet only registers
      # its Node at startup, so restarting scuttle alone (a switch that changes
      # only this unit) leaves the Node deleted until kubelet restarts. The new
      # definition takes effect on the next kubelet restart instead.
      restartIfChanged = false;
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target" cfg.kubeletService "network-online.target"];
      bindsTo = [cfg.kubeletService];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "simple";
        # drain, then delete; leave headroom beyond the drain timeout
        TimeoutStopSec = cfg.drainTimeout + 120;
        SuccessExitStatus = [0 143];
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in {1..60}; do [ -f ${cfg.kubeconfigPath} ] && exit 0; echo \"Waiting for ${cfg.kubeconfigPath} ($i/60)\"; sleep 5; done; echo \"ERROR: ${cfg.kubeconfigPath} not found after 5 minutes\"; exit 1'";
      } // optionalAttrs cfg.clearPodsOnDelete {
        RuntimeDirectory = "scuttle";
        RuntimeDirectoryPreserve = "yes";
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
            "-drain-timeout=${toString cfg.drainTimeout}s"
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
  });
}
