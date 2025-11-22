{
  lib,
  pkgs,
  config,
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
        containerd.runtimes.runc = {
          runtime_type = "io.containerd.runc.v2";
          options.SystemdCgroup = true;
        };
        cni = {
          bin_dir = "/opt/cni/bin";
          conf_dir = "/etc/cni/net.d";
        };
      };
    };
  };

  # Disable the NixOS kubernetes module components we don't want
  services.kubernetes = {
    roles = [];
    masterAddress = "qgr1-k8s.mole-bowfin.ts.net";
    package = pkgs.kubernetes.overrideAttrs (oldAttrs: rec {
      version = "1.34.0";
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
    proxy.enable = lib.mkForce false;
    flannel.enable = lib.mkForce false;

    kubelet = {
      enable = true;
      containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock";

      extraOpts = lib.concatStringsSep " " [
        "--config=/etc/kubernetes/kubelet-config.yaml"
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

  boot.kernelModules = ["br_netfilter" "overlay"];

  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = lib.mkDefault 1;
    "net.bridge.bridge-nf-call-ip6tables" = lib.mkDefault 1;
    "net.ipv4.ip_forward" = lib.mkDefault 1;
    "net.ipv6.conf.all.forwarding" = lib.mkDefault 1;
  };

  networking.firewall = {
    allowedTCPPorts = [10250];
    allowedTCPPortRanges = [
      {
        from = 30000;
        to = 32767;
      }
    ];
  };

  environment.systemPackages = with pkgs; [
    cri-tools
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/kubernetes 0750 root root -"
    "d /var/lib/kubelet 0750 root root -"
    "d /var/lib/kubelet/pki 0750 root root -"
    "d /opt/cni 0755 root root -"
    "d /opt/cni/bin 0755 root root -"
    "d /etc/cni/net.d 0755 root root -"
  ];

  # Link CNI plugins after directories are created
  systemd.services.link-cni-plugins = {
    description = "Link CNI plugins to /opt/cni/bin";
    wantedBy = ["multi-user.target"];
    after = ["local-fs.target"];
    before = ["kubelet.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      rm -rf /opt/cni/bin/*
      ln -sf ${pkgs.cni-plugins}/bin/* /opt/cni/bin/
    '';
  };

  swapDevices = lib.mkForce [];
  zramSwap.enable = lib.mkForce false;

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
      "/opt/cni"
    ];
  };
}
