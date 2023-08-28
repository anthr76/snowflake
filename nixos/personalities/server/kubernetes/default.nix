{ pkgs,lib, config }:
# let
#   #TODO: Make this more modular for more clusters
#   controlPlaneEndpoint = "https://cluster-0.scr1.rabbito.tech:6443";
# in
{
  imports = [
    ../default.nix
  ];
  sops.secrets = {
    kubelet-ca = {
      sopsFile = ./secrets.sops.yaml;
    };
    bootstrap-kubeconfig = {
      sopsFile = ./secrets.sops.yaml;
    };
  };
  services.kubernetes = {
    enable = true;
    pki.enable = false;
    clusterCidr = "10.244.0.0/16,fddf:f7bc:9670::/48";
    caFile = config.sops.secrets.kubelet-ca.path;
    kubelet = {
      enable = true;
      clusterDns = "10.96.0.10";
      containerRuntimeEndpoint = "unix:///run/crio/crio.sock";
      extraOpts = ''
        --bootstrap-kubeconfig=${config.sops.secrets.bootstrap-kubeconfig.path}
      '';
    };
  };
  virtualisation.containerd.enable = lib.mkForce false;
  # TODO: Enable this
  networking.firewall.enable = lib.mkForce false;
  virtualisation.cri-o = {
    enable = true;
    extraPackages = [
      pkgs.gvisor
    ];
    storageDriver = "btrfs";
  };
}
