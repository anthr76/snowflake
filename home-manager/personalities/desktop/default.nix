{ pkgs, ... }: {
  imports = [
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./email.nix
    ./chat
    ./wayland-wm/common
  ];
  home.packages = with pkgs; [
    moonlight-qt
    parsec-bin
    syncthing
    zoom-us
    bottles
    system76-keyboard-configurator
    podman-desktop
    mumble
    murmur
  ];
}
