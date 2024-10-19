{ pkgs, inputs, ... }: {
  imports = [
    ./vscode
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./firefox.nix
    ./email.nix
    ./chat
    ./wayland-wm/common
    ./wayland-wm/kde
    ./obs.nix
  ];
  home.packages = with pkgs; [
    moonlight-qt
    syncthing
    zoom-us
    system76-keyboard-configurator
    podman-desktop
    mumble
    murmur
    inputs.nix-gaming.packages.${pkgs.system}.wine-ge
    dxvk
    winetricks
    lightworks_2023_02_02
  ];
}
