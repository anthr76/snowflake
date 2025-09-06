{
  config,
  inputs,
  lib,
  modulesPath,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ../../personalities/desktop/wayland-wm/kde
  ];

  sops.secrets.e39-luks-password = {
    # TODO: poor secret name
    sopsFile = ../../../secrets/users.yaml;
  };
  i18n.defaultLocale = "en_US.UTF-8";
  # TODO: This was causing a eval failure
  # Ensure it's upstreammed
  hardware.framework.enableKmod = false;
  facter.reportPath = ./facter.json;

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
  boot.kernelModules = ["kvm-amd"];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  disko.devices = import ./disks.nix {
    disks = ["/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_24035A801792"];
    luksCreds = config.sops.secrets.e39-luks-password.path;
  };

  swapDevices = [];
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
  fonts.fontconfig = {
    antialias = true;
    subpixel.rgba = "rgb";
    hinting.style = "slight";
    defaultFonts.emoji = [
      "Noto Color Emoji"
    ];
  };
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 internal_regdb=y
    options cfg80211 crda_support=y
    options cfg80211 ieee80211_regdom="US"
  '';
  networking.wireless.iwd.settings = {
    General = {
      ControlPortOverNL80211 = false;
    };
  };
}
