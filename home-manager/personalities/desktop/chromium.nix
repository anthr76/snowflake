{ pkgs, config, ...}:
{
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
    ];
  };
}
