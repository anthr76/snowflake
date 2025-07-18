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
    # ./syncthing.nix
  ];
  home.packages = with pkgs; [
    moonlight-qt
    syncthing
    # Currently broken and using with flatpak for now.
    # zoom-us
    system76-keyboard-configurator
    uhk-agent
    podman-desktop
    mumble
    murmur
    (wineWowPackages.waylandFull.override {
      wineRelease = "stable";
      mingwSupport = true;
    })
    dxvk
    winetricks
    lightworks
    darktable
    shadps4
    yuki-iptv
    vorta
    prismlauncher
  ];
}
