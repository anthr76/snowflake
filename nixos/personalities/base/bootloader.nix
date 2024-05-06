{
  boot = {
    supportedFilesystems = [ "btrfs" ];
    loader = {
      efi = { canTouchEfiVariables = true; };
      grub = {
        efiSupport = true;
        device = "nodev";
        enableCryptodisk = true;
        configurationLimit = 15;
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
