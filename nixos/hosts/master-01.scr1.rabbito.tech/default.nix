{

  imports = [
    ../../personalities/server/kubernetes/control-plane
    ./disks.nix
  ];
  networking.hostName = "master-01";
}
