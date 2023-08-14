{ pkgs, lib, outputs, ... }: {
  imports = [
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./chat
    ./wayland-wm/common
  ];
}
