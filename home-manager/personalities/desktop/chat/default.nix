{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      telegram-desktop
      slack
      discord
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      fractal
      element-desktop
      # For Discord on Wayland
      wayland-push-to-talk-fix
      discover-overlay
    ];
  catppuccin.element-desktop.enable = pkgs.stdenv.isLinux;
}
