{
  imports = [
    ./apiserver.nix
    ./etcd.nix
    ./controller-manager.nix
    ./scheduler.nix
    ../default.nix
  ];
}
