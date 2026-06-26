{pkgs, ...}: {
  home.sessionPath = [
    "${pkgs.uutils-coreutils-noprefix}/bin"
  ];
}
