{pkgs, ...}: {
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
        "text/html" = "chromium-browser.desktop ";
        "x-scheme-handler/http" = "chromium-browser.desktop ";
        "x-scheme-handler/https" = "chromium-browser.desktop ";
        "x-www-browser" = "chromium-browser.desktop ";
        "x-scheme-handler/about" = "chromium-browser.desktop ";
        "x-scheme-handler/unknown" = "chromium-browser.desktop ";
        "application/pdf" = "chromium-browser.desktop ";
        "x-scheme-handler/element" = "element-desktop.desktop";
      };
    };
  };
}
