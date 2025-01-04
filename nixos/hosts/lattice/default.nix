{ config, inputs, lib, modulesPath, pkgs, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ../../personalities/desktop/wayland-wm/kde
  ];

  sops.secrets.e39-luks-password = {
    # TODO: poor secret name
    sopsFile = ../../../secrets/users.yaml;
  };

  boot.initrd.availableKernelModules = [
    "nvme"
    "thunderbolt"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
    "amdgpu"
  ];
  boot.kernelModules = [ "kvm-amd" ];
  hardware.enableAllFirmware = true;

  disko.devices = import ./disks.nix {
    disks = [ "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_24035A801792" ];
    luksCreds = config.sops.secrets.e39-luks-password.path;
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "lattice";
  networking.domain = "nwk3.rabbito.tech";
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  # boot.kernelPackages = pkgs.linuxPackages_testing;
  system.stateVersion = "23.05";
  # TODO: Find this on FW16
  environment.variables.DXVK_FILTER_DEVICE_NAME = "AMD Radeon RX 7700S (RADV NAVI33)";
  chaotic.nyx.overlay.onTopOf = "user-pkgs";
  services.scx.enable = true;
  services.scx.scheduler = "scx_bpfland";
  fonts.fontconfig = {
    antialias = true;
    subpixel.rgba = "rgb";
    hinting.style = "slight";
    defaultFonts.emoji = [
      "Noto Color Emoji"
    ];
  };
}