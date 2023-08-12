{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.loader.systemd-boot.consoleMode = "auto";
  boot.supportedFilesystems = [ "btrfs" ];
  boot.initrd.enable = true;
}
