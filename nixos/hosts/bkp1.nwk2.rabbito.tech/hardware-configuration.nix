{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    inputs.hardware.nixosModules.common-cpu-intel
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=rootfs" ];
    };

  fileSystems."/srv" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=rootfs/srv" ];
    };

  fileSystems."/var/lib/portables" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=rootfs/var/lib/portables" ];
    };

  fileSystems."/var/lib/machines" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=rootfs/var/lib/machines" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7F84-BB22";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/9b390384-9c28-4d8b-84c9-2edc8f1326ae";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
