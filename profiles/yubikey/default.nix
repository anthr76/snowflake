{
  self,
  config,
  lib,
  options,
  profiles,
  pkgs,
  ...
}: let
  yubicoPackages = builtins.attrValues {
    inherit
      (pkgs)
      yubikey-manager
      ;
  };
in {
  imports = with profiles; [ ssh ];
  services.udev.packages = yubicoPackages;
  environment.systemPackages = yubicoPackages;
  services.yubikey-agent.enable = true;
  programs.ssh.startAgent = false;
  services.pcscd.enable = true;
}
