{ ... }:
{
  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
  };
  # TODO: Breakout into WM specific area
  # home.packages = with pkgs; [
  #   xwaylandvideobridge
  # ];

  # systemd.user.services.xwaylandvideobridge = {
  #   Unit = {
  #     Description = "Screencast X11 apps in Wayland";
  #     After = [ "graphical-session.target" ];
  #   };

  #   Service = {
  #     ExecStart = "${pkgs.xwaylandvideobridge}/bin/xwaylandvideobridge";
  #   };

  #   Install = { WantedBy = [ "graphical-session.target" ]; };
  # };
}
