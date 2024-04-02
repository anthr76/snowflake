{ pkgs, config, ... }: {
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
