{ config, inputs, lib, modulesPath, pkgs, comfyui, ... }: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.disko.nixosModules.disko
    ../../personalities/desktop/wayland-wm/kde
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-cpu-amd-pstate
    inputs.hardware.nixosModules.common-pc-ssd
    # TODO: Check if this breaks Luks input on startup
    # inputs.hardware.nixosModules.common-hidpi
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
  boot.kernelParams = [ "initcall_blacklist=simpledrm_platform_driver_init" ];
  hardware.wirelessRegulatoryDatabase = true;
  boot.extraModprobeConfig = ''
    options cfg80211 internal_regdb=y
    options cfg80211 crda_support=y
    options cfg80211 ieee80211_regdom="US"
  '';
  hardware.enableAllFirmware = true;

  disko.devices = import ./disks.nix {
    disks = [ "/dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48821069801973" ];
    luksCreds = config.sops.secrets.e39-luks-password.path;
  };

  swapDevices = [ ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = lib.mkDefault true;
  networking.hostName = "f80";
  networking.domain = "nwk3.rabbito.tech";
  hardware.enableRedistributableFirmware = true;
  # https://github.com/morrownr/USB-WiFi/blob/main/home/How_to_Install_Firmware_for_Mediatek_based_USB_WiFi_adapters.md
  # hardware.firmware = [
  #   (pkgs.runCommand "mt7922-firmware" {} ''
  #     mkdir -p "$out/lib/firmware/mediatek"
  #     cp '${pkgs.firmwareLinuxNonfree}'/lib/firmware/mediatek/WIFI_MT7922_patch_mcu_1_1_hdr.* "$out/lib/firmware/mediatek"
  #     cp '${pkgs.firmwareLinuxNonfree}'/lib/firmware/mediatek/WIFI_RAM_CODE_MT7922_1.* "$out/lib/firmware/mediatek"
  #     cp '${pkgs.firmwareLinuxNonfree}'/lib/firmware/mediatek/BT_RAM_CODE_MT7922_1_1_hdr.* "$out/lib/firmware/mediatek"
  #   '')
  # ];
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  # boot.kernelPackages = pkgs.linuxPackages_testing;
  system.stateVersion = "23.05";
  environment.variables.DXVK_FILTER_DEVICE_NAME =
    "AMD Radeon RX 7900 XTX (RADV NAVI31)";
  # Debugging Gamescope
  environment.systemPackages = [ pkgs.gdb ];
  chaotic.nyx.overlay.onTopOf = "user-pkgs";
  fonts.fontconfig = {
    antialias = false;
    subpixel.rgba = "none";
    hinting.style = "full";
    defaultFonts.emoji = [
      "Noto Color Emoji"
    ];
  };
}
