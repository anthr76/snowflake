{ config, inputs, lib, pkgs, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ../../personalities/base
    ../../personalities/server
  ];

  disko.devices = import ./disks.nix {
    disks = [ "/dev/vda" ];
  };

  fileSystems."/" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=rootfs" ];
    };

  fileSystems."/srv" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=rootfs/srv" ];
    };

  fileSystems."/var/lib/portables" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=rootfs/var/lib/portables" ];
    };

  fileSystems."/var/lib/machines" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=rootfs/var/lib/machines" ];
    };

  fileSystems."/boot" = lib.mkForce
    { device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
    };

  fileSystems."/nix" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/home" = lib.mkForce
    { device = "/dev/disk/by-partlabel/root";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };


  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "lga-test1";
}
