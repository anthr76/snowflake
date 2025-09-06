{
  pkgs,
  lib,
  ...
}: {
  networking.firewall = {
    enable = true;
  };
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };
}
