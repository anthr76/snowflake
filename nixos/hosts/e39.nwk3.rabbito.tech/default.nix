{ config, inputs, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ../../personalities/physical
    ../../personalities/desktop/wayland-wm/gnome
  ];

  sops.secrets.e39-luks-password = {
    # TODO: poor secret name
    sopsFile = ../../../secrets/users.yaml;
  };

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-amd" ];

  disko.devices = import ./disks.nix {
    disks = [ "/dev/disk/by-id/nvme-PCIe_SSD_21050610240876" ];
    luksCreds = config.sops.secrets.e39-luks-password.path;
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "e39";
}
