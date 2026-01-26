{pkgs, ...}: {
  imports = [
    ./vscode
    ./fonts.nix
    ./ghostty.nix
    ./chat
    ./agentic-coding.nix
  ];

  home.packages = with pkgs; [
    raycast
    maccy
    betterdisplay
  ];
}
