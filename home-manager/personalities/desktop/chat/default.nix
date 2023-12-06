{ pkgs, ... }: {
  home.packages = with pkgs; [
    unstable.telegram-desktop
    fractal-next
    slack
    element-desktop
    discord
  ];
}
