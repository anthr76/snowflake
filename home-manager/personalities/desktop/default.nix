{ pkgs, ... }: {
  imports = [
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./email.nix
    ./chat
    ./flameshot.nix
    ./wayland-wm/common
  ];
  home.packages = with pkgs; [
    moonlight-qt
    parsec-bin
    syncthing
    pcoip-client
  ];
}
