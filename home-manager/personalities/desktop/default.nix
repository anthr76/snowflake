{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./vscode
    ./fonts.nix
    ./wezterm.nix
    ./chromium.nix
    ./zen.nix
    ./firefox.nix
    ./email.nix
    ./chat
    ./wayland-wm/common
    ./wayland-wm/kde
    ./obs.nix
    ./agentic-coding.nix
    ./ghostty.nix
    ./halloy.nix
    # ./syncthing.nix
  ];
  home.packages = with pkgs; [
    moonlight-qt
    syncthing
    # Currently broken and using with flatpak for now.
    # zoom-us
    system76-keyboard-configurator
    uhk-agent
    murmur
    bottles
    lightworks
    darktable
    # TODO: Currently broken
    # shadps4
    vorta
    prismlauncher
    minicom
    high-tide
  ];
  #TODO:https://github.com/NixOS/nixpkgs/pull/429473
  nixpkgs.config.permittedInsecurePackages = [
    "libsoup-2.74.3"
  ];
}
