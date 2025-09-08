{ inputs, ... }: {

  imports = [
    inputs.disko.nixosModules.disko
    ../../personalities/base
    ../../personalities/server
    ./disks.nix
  ];

  services.observability.vector.extraLabels = {
    site = "nwk2";
  };

  networking.hostName = "bkp1";
  networking.domain = "nwk2.rabbito.tech";
  system.stateVersion = "23.05";
  facter.reportPath = ./facter.json;
}
