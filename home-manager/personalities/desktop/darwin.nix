{ pkgs, ...}: {
  imports = [
    ./vscode
    ./fonts.nix
  ];
  home.packages = with pkgs; [ iterm2 rectangle ];
}
