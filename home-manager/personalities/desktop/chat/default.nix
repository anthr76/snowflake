{ pkgs, ... }: {
  home.packages = with pkgs; [
    unstable.telegram-desktop
    fractal-next
    unstable.webcord-vencord
    slack
    element-desktop
  ];
}
