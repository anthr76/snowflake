{ ... }:
{
  imports = [
    ./gnome-keyring.nix
    ./easyeffects.nix
  ];
  # TODO: Breakout into WM specific area
  # home.packages = with pkgs; [
  #   grim
  #   imv
  #   slurp
  #   waypipe
  #   wl-clipboard
  # ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
  };
}
