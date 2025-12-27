{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: {
  sops.secrets = {
    qgr1-ca = {
      sopsFile = ../../../../secrets/users.yaml;
      path = "/var/lib/kubelet/pki/ca.crt";
      mode = "0644";
      owner = "root";
      group = "root";
      restartUnits = ["kubelet.service"];
    };
    qgr1-bootstrap-kubeconfig = {
      sopsFile = ../../../../secrets/users.yaml;
      path = "/var/lib/kubernetes/bootstrap-kubeconfig";
      mode = "0600";
      owner = "root";
      group = "root";
      restartUnits = ["kubelet.service"];
    };
  };

  virtualisation.containerd = {
    enable = true;
    settings = {
      version = 2;
      plugins."io.containerd.grpc.v1.cri" = {
        sandbox_image = "registry.k8s.io/pause:3.9";
        registry.config_path = "/etc/containerd/certs.d";
        containerd = {
          discard_unpacked_layers = false;
          runtimes.runc = {
            runtime_type = "io.containerd.runc.v2";
            options.SystemdCgroup = true;
          };
        };
        cni = {
          bin_dir = "/opt/cni/bin";
          conf_dir = "/etc/cni/net.d";
        };
      };
    };
  };

  services.kubernetes = {
    roles = [];
    masterAddress = "qgr1-k8s.mole-bowfin.ts.net";
    package = pkgs.kubernetes.overrideAttrs (oldAttrs: rec {
      version = "1.35.0";
      src = pkgs.fetchFromGitHub {
        owner = "kubernetes";
        repo = "kubernetes";
        rev = "v${version}";
        hash = "sha256-rKy4X01pX+kovJ8b2JHV0KuzHJ7PYZ08eDEO3GeuPoc=";
      };
    });

    apiserver.enable = lib.mkForce false;
    scheduler.enable = lib.mkForce false;
    controllerManager.enable = lib.mkForce false;
    addonManager.enable = lib.mkForce false;
    addons.dns.enable = lib.mkForce false;
    proxy.enable = lib.mkForce false;
    flannel.enable = lib.mkForce false;

    kubelet = {
      enable = true;
      containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock";

      extraOpts = lib.concatStringsSep " " [
        "--config=/etc/kubernetes/kubelet-config.yaml"
        "--root-dir=/var/lib/kubelet"
        "--bootstrap-kubeconfig=/var/lib/kubernetes/bootstrap-kubeconfig"
        "--kubeconfig=/var/lib/kubernetes/kubeconfig"
        "--cert-dir=/var/lib/kubernetes/pki"
        "--register-node=true"
        "--node-labels=node.kubernetes.io/worker="
        "--register-with-taints="
        "--hostname-override=${config.networking.hostName}"
      ];
    };
  };

  # crictl configuration
  environment.etc."crictl.yaml".text = lib.generators.toYAML {} {
    runtime-endpoint = "unix:///run/containerd/containerd.sock";
    image-endpoint = "unix:///run/containerd/containerd.sock";
    timeout = 10;
    debug = false;
  };

  # TODO: Make stable
  system.autoUpgrade = {
    enable = true;
    flake = "github:anthr76/snowflake";
    operation = "boot";
    persistent = true;
  };

  # Kubelet configuration file
  environment.etc."kubernetes/kubelet-config.yaml".text = lib.generators.toYAML {} {
    apiVersion = "kubelet.config.k8s.io/v1beta1";
    kind = "KubeletConfiguration";

    authentication = {
      anonymous.enabled = false;
      webhook = {
        enabled = true;
        cacheTTL = "2m";
      };
      x509.clientCAFile = "/var/lib/kubelet/pki/ca.crt";
    };

    authorization = {
      mode = "Webhook";
      webhook.cacheAuthorizedTTL = "5m";
      webhook.cacheUnauthorizedTTL = "30s";
    };

    rotateCertificates = true;
    serverTLSBootstrap = true;

    cgroupDriver = "systemd";

    featureGates = {
      RotateKubeletServerCertificate = true;
    };

    clusterDNS = ["10.96.0.10"];
    clusterDomain = "cluster.local";
    containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock";

    enableDebuggingHandlers = true;
    healthzBindAddress = "127.0.0.1";
    healthzPort = 10248;

    maxPods = 110;
    podsPerCore = 0;

    evictionHard = {
      "memory.available" = "100Mi";
      "nodefs.available" = "10%";
      "nodefs.inodesFree" = "5%";
      "imagefs.available" = "15%";
    };
  };

  boot.kernelModules = ["br_netfilter" "overlay" "rbd" "nbd"];

  boot.kernel.sysctl = {
    # Kubernetes networking
    "net.bridge.bridge-nf-call-iptables" = lib.mkDefault 1;
    "net.bridge.bridge-nf-call-ip6tables" = lib.mkDefault 1;
    "net.ipv4.ip_forward" = lib.mkDefault 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;

    # Network performance tuning
    "net.core.default_qdisc" = lib.mkDefault "fq";
    "net.core.rmem_max" = lib.mkDefault 67108864; # 64 MB for high-throughput apps (cloudflared QUIC, etc)
    "net.core.wmem_max" = lib.mkDefault 67108864; # 64 MB
    "net.ipv4.tcp_congestion_control" = lib.mkDefault "bbr";
    "net.ipv4.tcp_fastopen" = lib.mkDefault 3;
    "net.ipv4.tcp_mtu_probing" = lib.mkDefault 1;
    "net.ipv4.tcp_rmem" = lib.mkDefault "4096 87380 33554432";
    "net.ipv4.tcp_window_scaling" = lib.mkDefault 1;
    "net.ipv4.tcp_wmem" = lib.mkDefault "4096 65536 33554432";

    # ARP cache tuning for large number of pods
    "net.ipv4.neigh.default.gc_thresh1" = lib.mkDefault 4096;
    "net.ipv4.neigh.default.gc_thresh2" = lib.mkDefault 8192;
    "net.ipv4.neigh.default.gc_thresh3" = lib.mkDefault 16384;

    # NFS client tuning
    "sunrpc.tcp_max_slot_table_entries" = lib.mkDefault 128;
    "sunrpc.tcp_slot_table_entries" = lib.mkDefault 128;

    # User namespaces for rootless containers
    "user.max_user_namespaces" = lib.mkDefault 11255;

    # Huge pages for performance
    "vm.nr_hugepages" = lib.mkDefault 1024;
  };

  # TODO: Should we care about this?
  networking.firewall.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    cri-tools
    cni-plugins
    # TODO: Audit if this is needed even.
    # TODO: https://github.com/NixOS/nixpkgs/pull/466427
    inputs.nixpkgs-stable.legacyPackages.${pkgs.system}.ceph-client
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/kubernetes 0750 root root -"
    "d /var/lib/kubelet 0750 root root -"
    "d /var/lib/kubelet/pki 0750 root root -"
    "d /var/lib/kubelet/plugins 0750 root root -"
    "d /var/lib/kubelet/pods 0750 root root -"
    "d /var/lib/kubelet/plugins_registry 0750 root root -"
  ];

  swapDevices = lib.mkForce [];
  zramSwap.enable = lib.mkForce false;

  # Check if reboot is needed after activation
  # Compares booted system with new system - any difference triggers sentinel
  system.activationScripts.needsreboot = {
    supportsDryActivation = true;
    text = ''
      booted="/run/booted-system"
      if [[ -e "$booted" ]]; then
        booted_system=$(readlink -f "$booted")
        new_system=$(readlink -f "$systemConfig")

        if [[ "$booted_system" != "$new_system" ]]; then
          echo -e "\033[33m>>> Reboot required: system configuration changed\033[0m"
          echo "NixOS: booted $booted_system, current $new_system" > /var/run/reboot-required
        else
          rm -f /var/run/reboot-required
        fi
      fi
    '';
  };

  services.scuttle = {
    enable = true;
    platform = null;
    kubeconfigPath = "/var/lib/kubernetes/kubeconfig";
    nodeName = config.networking.hostName;
    drain = true;
    delete = true;
    uncordon = true;

    logLevel = "info";
  };

  environment.persistence."/persist" = {
    directories = [
      "/var/lib/containerd"
      "/etc/cni"
      "/var/lib/rook"
      # TODO: Audit this?
      "/opt/cni/bin"
    ];
  };
}
