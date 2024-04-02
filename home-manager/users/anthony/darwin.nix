{pkgs, ... }:{
  home = {
    username = "anthony";
    homeDirectory = "/Users/anthony";
  };
  # Yubikey glue usually done only in NixOS.
  home.packages = with pkgs; [
    yubico-piv-tool
  ];
  programs.ssh.extraConfig = ''
    Host *
      PKCS11Provider "${pkgs.yubico-piv-tool}/lib/libykcs11.dylib"
  '';
}
