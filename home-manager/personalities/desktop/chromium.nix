{ ... }: {
  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
  programs.chromium = {
    enable = true;
    # package = pkgs.google-chrome;
    extensions = [
      { id = "nngceckbapebfimnlniiiahkandclblb"; } # Bitwarden
      { id = "ckhlfagjncfmdieecfekjbpnnaekhlhd"; } # No Mouse Wheel Zoom
      {
        # adnauseam
        id = "ilkggpgmkemaniponkfgnkonpajankkm";
        crxPath = builtins.fetchurl {
          name = "chromium-web-store.crx";
          url = "https://github.com/dhowe/AdNauseam/releases/download/v3.24.0/adnauseam-3.24.0.chromium.crx";
          sha256 = "sha256:0hy5x1q84q4alg412ic23fq39afn75kmfnmb475sd8bwvmr4v8q6";
        };
        version = "3.24.0";
      }
    ];
    commandLineArgs = [
      "--ignore-gpu-blocklist"
      "--enable-logging=stderr"
      "--disable-features=WaylandFractionalScaleV1"
      "--enable-features=TouchpadOverscrollHistoryNavigation"
      "--ignore-gpu-blocklist"
      # TODO: Work around Mesa issue @ d7ba0b445a025e6d105515527a78f1738e7e91be
      # https://github.com/NixOS/nixpkgs/issues/244742
      "--disable-gpu-shader-disk-cache"
      # fd -0 cache | xargs --null rm -rf $0
    ];
  };
}
