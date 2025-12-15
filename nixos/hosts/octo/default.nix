{
  inputs,
  lib,
  modulesPath,
  pkgs,
  config,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-pc-ssd
    ./disks.nix
    ../../personalities/desktop/game-console.nix
  ];

  boot.initrd.availableKernelModules = ["amdgpu" "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.initrd.kernelModules = ["amdgpu"];
  boot.kernelModules = ["kvm-amd"];
  services.xserver.videoDrivers = ["amdgpu"];
  boot.extraModulePackages = [];
  time.timeZone = "America/New_York";

  swapDevices = [];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "octo";
  networking.domain = "nwk3.rabbito.tech";
  system.stateVersion = "23.11";
  environment.systemPackages = [pkgs.gdb];
  hardware.enableAllFirmware = true;
}
