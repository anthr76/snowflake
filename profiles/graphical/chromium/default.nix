{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    chromium
  ];
  
  nixpkgs.config.chromium.commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform=wayland";

}
