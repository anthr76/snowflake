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
        "text/html" = "choromium-browser.desktop";
        "x-scheme-handler/http" = "choromium-browser.desktop";
        "x-scheme-handler/https" = "choromium-browser.desktop";
        "x-www-browser" = "choromium-browser.desktop";
        "x-scheme-handler/about" = "choromium-browser.desktop";
        "x-scheme-handler/unknown" = "choromium-browser.desktop";
        "application/pdf" = "choromium-browser.desktop";
        "x-scheme-handler/element" = "element-desktop.desktop";
        # "x-scheme-handler/bs-sso-authorized" = "ubuntu-22-04-BlastShield.desktop";
      };
    };
  };
}
