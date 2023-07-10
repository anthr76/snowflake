{ pkgs, ... }:
{
  imports = [
    ./hyprland-vnc.nix
  ];

  home.packages = with pkgs; [
    grim
    imv
    slurp
    waypipe
    wl-clipboard
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
  };
}
