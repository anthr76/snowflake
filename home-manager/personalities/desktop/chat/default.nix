{ pkgs, ... }: {
  home.packages = with pkgs; [
    telegram-desktop
    fractal
    slack
    element-desktop
    discord
    # For Discord
    wayland-push-to-talk-fix
    discover-overlay
  ];
  catppuccin.element-desktop.enable = true;

}
