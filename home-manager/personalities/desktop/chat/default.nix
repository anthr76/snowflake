{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs;
    [
      slack
      discord
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      fractal
      element-desktop
      # For Discord on Wayland
      wayland-push-to-talk-fix
      discover-overlay
      # TODO: Bugs on mac
      telegram-desktop
    ];
  catppuccin.element-desktop.enable = pkgs.stdenv.isLinux;
}
