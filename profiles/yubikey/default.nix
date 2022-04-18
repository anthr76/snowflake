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
      yubico-piv-tool
      yubioath-desktop
      #"lxqt.lxqt-openssh-askpass"
      ;
  };
in {
  imports = with profiles; [ ssh misc.gnupg];
  services.udev.packages = yubicoPackages;
  services.dbus.packages = [ pkgs.gcr ];
  environment.systemPackages = yubicoPackages;
  # Conflicts with gpg
  services.yubikey-agent.enable = false;
  programs.ssh-fixed.extraConfig = 
    ''
      Host *
        PKCS11Provider "${pkgs.yubico-piv-tool}/lib/libykcs11.so"
    '';
  # I think I should've used an overlay but, https://github.com/NixOS/nixpkgs/pull/169155
  programs.ssh-fixed.startAgent = true;
  programs.ssh-fixed.agentPKCS11Whitelist = "${pkgs.yubico-piv-tool}/lib/libykcs11*";
  #programs.ssh-fixed.askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
  services.pcscd.enable = true;
}
