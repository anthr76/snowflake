{ inputs, lib, config, modulesPath, ... }:
{

  imports = [
    ../../personalities/server/kubernetes/control-plane
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];
  networking.hostName = "master-04";
  # TODO: Refactor to use `networking.domain`
  networking.domain = "tenant-29c7a3-baggie.coreweave.cloud";
  sops.secrets.e39-luks-password = {
    # TODO: poor secret name
    sopsFile = ../../../secrets/users.yaml;
  };
  disko.devices = import ./disks.nix {
    disks = [ "/dev/vda" ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
