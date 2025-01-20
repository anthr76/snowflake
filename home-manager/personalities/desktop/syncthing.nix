{
  services.syncthing = {
    enable = true;
    tray.enable = true;
    settings = {
      options = {
        localAnnounceEnabled = true;
      };
    };
  };
}
