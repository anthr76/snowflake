{
  imports = [
    ../../default.nix
  ];
  services = {
    xserver = {
      enable = true;
      desktopManager.gnome = {
        enable = true;
      };
      displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = true;
      };
    };
    geoclue2.enable = true;
  };
}
