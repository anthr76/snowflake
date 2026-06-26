{
  inputs,
  lib,
  ...
}: {
  imports = [
    inputs.disko.nixosModules.disko
    inputs.impermanence.nixosModules.impermanence
    ../../personalities/base
    ../../personalities/base/impermanence.nix
    ../../personalities/server
    ../../personalities/server/kubernetes-worker
    ./disks.nix
  ];

  networking.hostName = "worker-1";
  networking.domain = "qgr1.rabbito.tech";
  system.stateVersion = "24.11";
  facter.reportPath = ./facter.json;

  fileSystems."/persist".neededForBoot = true;
}
