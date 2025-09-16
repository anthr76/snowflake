{
  pkgs,
  lib,
  ...
}: {
  networking.firewall = {
    enable = true;
  };
  networking.wireless = {
    fallbackToWPA2 = false;
  };
  networking.networkmanager = {
    enable = true;
    wifi.backend = "wpa_supplicant";
  };
}
