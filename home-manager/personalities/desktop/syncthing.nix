{
  services.syncthing = {
    enable = true;
    tray.enable = true;
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
  };
}
