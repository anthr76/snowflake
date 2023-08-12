{
  services = {
    xserver = {
      desktopManager.gnome = {
        enable = true;
      };
      displayManager.gdm = {
        enable = true;
        autoSuspend = true;
      };
    };
    geoclue2.enable = true;
  };
}
