{ pkgs, ... }: {
  home.packages = with pkgs; [
    telegram-desktop
    fractal-next
    unstable.webcord-vencord
    slack
    element-desktop
  ];
}
