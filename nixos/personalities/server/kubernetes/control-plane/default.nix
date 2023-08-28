{
  imports = [
    ./apiserver.nix
    ./etcd.nix
    ./controller-manager.nix
    ./scheduler.nix
    ../default.nix
  ];
  services.kubernetes.roles = ["master"];
}
