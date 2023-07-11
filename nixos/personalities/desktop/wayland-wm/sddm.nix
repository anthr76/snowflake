{ pkgs, ... }:
{
  services.xserver.displayManager.sddm = {
    enable = true;
    settings = {
      general = {
        DisplayServer = "wayland";
        GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
      };
      wayland = {
        CompositorCommand = "";
      };
    };
  };
}
