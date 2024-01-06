{ pkgs, ... }:
{
  home.pointerCursor = {
    name = "breeze_cursors";
    package = pkgs.breeze-icons;
    #   x11.enable = true;
    #   gtk.enable = true;
  };
}
