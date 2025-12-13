{pkgs, ...}: {
  programs.fish.enable = true;
  environment.shells = [
    pkgs.fish
  ];
}
