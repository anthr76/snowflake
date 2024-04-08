{ pkgs, ... }: {
  home.packages = with pkgs; [
    unstable.telegram-desktop
    fractal-next
    slack
    element-desktop
    discord
    # For Discord
    wayland-push-to-talk-fix
    discover-overlay
  ];
}
