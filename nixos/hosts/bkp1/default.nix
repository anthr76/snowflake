{ inputs, outputs, lib, config, pkgs, ... }: {

  imports = [
    inputs.disko.nixosModules.disko
    ../../personalities/base
    ../../personalities/server
    ./disks.nix
  ];
  networking.hostName = "bkp1";
  networking.domain = "nwk2.rabbito.tech";
  system.stateVersion = "23.05";
  facter.reportPath = ./facter.json;
}
