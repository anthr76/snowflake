{ pkgs, ... }: {
  home = {
    username = "anthony";
    homeDirectory = "/home/anthony";
    # pointerCursor = {
    #   name = "Vanilla-DMZ";
    #   package = pkgs.vanilla-dmz;
    #   size = 128;
    #   x11.enable = true;
    #   gtk.enable = true;
    # };
  };
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      associations.added = {
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
      };
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-www-browser" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
        "application/pdf" = "firefox.desktop";
        "x-scheme-handler/element" = "element-desktop.desktop";
      };
    };
  };
}
