{ pkgs, inputs, ... }:
let
  yubicoPackages = builtins.attrValues {
    inherit (pkgs)
      yubikey-manager yubico-piv-tool yubioath-flutter
    ;
  };
in {
  disabledModules = [
    "${inputs.nixpkgs}/nixos/modules/programs/ssh.nix"
  ];
  imports = [
    "${inputs.nixpkgs-pr-169155}/nixos/modules/programs/ssh.nix"
  ];
  services.udev.packages = yubicoPackages;
  environment.systemPackages = yubicoPackages;
  programs.ssh.extraConfig = ''
    Host *
      PKCS11Provider "${pkgs.yubico-piv-tool}/lib/libykcs11.so"
  '';
  programs.ssh.startAgent = true;
  programs.ssh.agentPKCS11Whitelist =
    "${pkgs.yubico-piv-tool}/lib/libykcs11*";
  services.pcscd.enable = true;
}
