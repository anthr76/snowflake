{ inputs, lib, config, modulesPath, ... }:
{

  imports = [
    ../../personalities/server/kubernetes/control-plane
    ../../personalities/server/tailscale.nix
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
  ];
  # TODO: Refactor to use `networking.domain`
  networking = {
    hostName = "master-04";
    domain = "mole-bowfin.ts.net";
  };
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
