{ pkgs, inputs, ... }:
let
  yubicoPackages = builtins.attrValues {
    inherit (pkgs) yubikey-manager yubico-piv-tool yubioath-flutter;
  };
in {
  services.udev.packages = yubicoPackages;
  environment.systemPackages = yubicoPackages;
}
