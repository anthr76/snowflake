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
  boot.kernelModules = [ "kvm-intel" ];

  disko.devices = import ./disks.nix {
    disks = [ "/dev/disk/by-id/nvme-SAMSUNG_MZVL21T0HCLR-00B00_S676NX0RA76311" ];
    luksCreds = config.sops.secrets.e39-luks-password.path;
  };

  boot.initrd.luks.devices.crypted = lib.mkForce
    {
      device = "/dev/disk/by-partlabel/disk-main-luks";
    };

  fileSystems."/" = lib.mkForce
    { device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [ "subvol=root" ];
    };

  fileSystems."/boot" = lib.mkForce
    { device = "/dev/disk/by-partlabel/EFI";
      fsType = "vfat";
    };

  fileSystems."/nix" = lib.mkForce
    { device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

  fileSystems."/home" = lib.mkForce
    { device = "/dev/mapper/crypted";
      fsType = "btrfs";
      options = [ "subvol=home" ];
    };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "e39";
}
