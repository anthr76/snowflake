{
  boot = {
    supportedFilesystems = [ "btrfs" ];
    loader = {
      efi = { canTouchEfiVariables = true; };
      systemd-boot = {
        enable = true;
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
