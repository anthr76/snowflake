{pkgs, ...}: {
  programs.go = {
    enable = true;
    package = pkgs.go-bin.latestStable;
  };
}
