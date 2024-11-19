{ pkgs, ... }: {
  imports = [ ../../darkman.nix ];
  home.pointerCursor = {
    name = "breeze_cursors";
    package = pkgs.breeze-icons;
    #   x11.enable = true;
    #   gtk.enable = true;
  };
  services.darkman = {
    darkModeScripts = {
      kde-global = ''
        ${pkgs.kdePackages.plasma-workspace}/bin/lookandfeeltool -platform offscreen --apply "org.kde.breezedark.desktop"
      '';
      kde-gtk-theme = ''
        ${pkgs.dbus}/bin/dbus-send --session --dest=org.kde.GtkConfig \
             --type=method_call /GtkConfig org.kde.GtkConfig.setGtkTheme "string:Breeze-dark-gtk"
      '';
    };
    lightModeScripts = {
      kde-global = ''
        ${pkgs.kdePackages.plasma-workspace}/bin/lookandfeeltool -platform offscreen --apply "org.kde.breeze.desktop"
      '';
      kde-gtk-theme = ''
        ${pkgs.dbus}/bin/dbus-send --session --dest=org.kde.GtkConfig \
             --type=method_call /GtkConfig org.kde.GtkConfig.setGtkTheme "string:Default"
      '';
    };
  };
}
