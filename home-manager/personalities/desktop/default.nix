{ pkgs, lib, outputs, ... }: {
  imports = [
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./email.nix
    ./chat
    ./wayland-wm/common
  ];
}
