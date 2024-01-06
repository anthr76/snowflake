{ pkgs, ... }:
{
  imports = [
    ./gnome-keyring.nix
  ];
  # TODO: Breakout into WM specific area
  home.packages = with pkgs; [
    xwaylandvideobridge
  ];

  systemd.user.services.xwaylandvideobridge = {
    Unit = {
      Description = "Screencast X11 apps in Wayland";
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.xwaylandvideobridge}/bin/xwaylandvideobridge";
    };

    Install = { WantedBy = [ "graphical-session.target" ]; };
  };
}
