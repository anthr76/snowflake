{
  # boot.loader.systemd-boot.enable = true;
  boot = {
    supportedFilesystems = [ "btrfs" ];
    loader = {
      efi = {
        canTouchEfiVariables = true;
      };
      grub = {
         efiSupport = true;
         device = "nodev";
         enableCryptodisk = true;
      };
    };
    initrd = {
      enable = true;
      systemd.enable = true;
      systemd.emergencyAccess = true;
      supportedFilesystems = [ "btrfs" ];
    };
  };
}
