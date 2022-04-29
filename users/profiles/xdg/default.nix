{
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "google-chrome-unstable.desktop";
        "x-scheme-handler/http" = "google-chrome-unstable.desktop";
        "x-scheme-handler/https" = "google-chrome-unstable.desktop";
        "x-www-browser" = "google-chrome-unstable.desktop";
        "x-scheme-handler/about" = "google-chrome-unstable.desktop";
        "x-scheme-handler/unknown" = "google-chrome-unstable.desktop";
        "application/pdf" = "google-chrome-unstable.desktop";
        "x-scheme-handler/element" = "element-desktop.desktop";
      };
    };
  };
}
