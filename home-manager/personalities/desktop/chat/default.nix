{ pkgs, ... }: {
  home.packages = with pkgs; [
    telegram-desktop
    fractal-next
    slack
    element-desktop
    discord-krisp
    # For Discord
    wayland-push-to-talk-fix
    discover-overlay
  ];
  catppuccin.element-desktop.enable = true;

}
