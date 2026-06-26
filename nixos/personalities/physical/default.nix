{
  pkgs,
  inputs,
  ...
}: let
  yubicoPackages = builtins.attrValues {
    inherit (pkgs) yubikey-manager yubico-piv-tool yubioath-flutter;
  };
in {
  disabledModules = [
    "${inputs.nixpkgs}/nixos/modules/programs/ssh.nix"
  ];
  imports = [
    "${inputs.nixpkgs-pr-169155}/nixos/modules/programs/ssh.nix"
    ./tpm2.nix
    ./yubikey.nix
    ./logiops.nix
  ];
  programs.ssh.extraConfig = ''
    Host *
      PKCS11Provider "${pkgs.tpm2-pkcs11}/lib/libtpm2_pkcs11.so"
  '';
  programs.ssh.startAgent = true;
  programs.ssh.agentPKCS11Whitelist = "/nix/store/*";
  services.pcscd = {
    enable = true;
  };
  services.fwupd.enable = true;
  services.fwupd.extraRemotes = ["lvfs-testing"];
}
