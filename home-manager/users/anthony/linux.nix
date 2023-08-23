  {pkgs, ...}: {
  home = {
    username = "anthony";
    homeDirectory = "/home/anthony";
    pointerCursor = {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
      size = 128;
      x11.enable = true;
      gtk.enable = true;
    };
  };
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-www-browser" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";
        "application/pdf" = "google-chrome.desktop";
        "x-scheme-handler/element" = "element-desktop.desktop";
        # "x-scheme-handler/bs-sso-authorized" = "ubuntu-22-04-BlastShield.desktop";
      };
    };
  };
}
