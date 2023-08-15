{ pkgs, ... }: {
  home.packages = with pkgs; [
    telegram-desktop
    fractal-next
    webcord-vencord
    slack
  ];
}
