{ pkgs, lib, ... }: {
  imports = [ ../git/default.nix ];
  programs.git = {
    signing.key = "0xA0186249";
    extraConfig = {
      gpg.format = "x509";
    };
    userEmail = "anthony.rabbito@sectigo.com";
    };
  home.file.".gnupg/trustlist.txt".text = ''
    # comodoca
    D1:EB:23:A4:6D:17:D6:8F:D9:25:64:C2:F1:F1:60:17:64:D8:E3:49
  '';

}
