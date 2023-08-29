{ pkgs,lib, config, ... }:
{
  imports = [
    ../default.nix
  ];
  sops.secrets = {
    kubelet-ca = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
    bootstrap-kubeconfig = {
      sopsFile = ./secrets.sops.yaml;
      owner = config.users.users.kubernetes.name;
      group = config.users.users.kubernetes.group;
    };
  };
  services.kubernetes = {
    easyCerts = false;
    masterAddress = "https://cluster-0.scr1.rabbito.tech:6443";
    pki.enable = false;
    clusterCidr = "10.244.0.0/16,fddf:f7bc:9670::/48";
    caFile = config.sops.secrets.kubelet-ca.path;
    kubelet = {
      enable = true;
      clusterDns = "10.96.0.10";
      containerRuntimeEndpoint = "unix:///run/crio/crio.sock";
      extraOpts = ''
        --bootstrap-kubeconfig=${config.sops.secrets.bootstrap-kubeconfig.path}
        --rotate-certificates=true
        --rotate-server-certificates=true
      '';
    };
  };
  virtualisation.containerd.enable = lib.mkForce false;
  networking.firewall.enable = lib.mkForce false;
  virtualisation.cri-o = {
    enable = true;
    extraPackages = [
      pkgs.gvisor
    ];
    storageDriver = "btrfs";
  };
  # https://github.com/NixOS/nixpkgs/issues/130804
  environment.etc."cni/net.d".enable = false;
}
