{pkgs, lib, ...}: {
  imports = [ ../git/default.nix ];
  programs.git.signing.key = "2FF9285B23C8C213CFDBD6314B28A1FDFF5302A6";
  programs.git.userEmail = "anthony.rabbito@sectigo.com";
}
