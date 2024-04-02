{ pkgs, ... }: {
  # TODO: In 2023 SDDM should not need X11 to start. Make that go away.
  services.xserver.enable = true;
  services.xserver.displayManager.sddm = {
    enable = true;
    settings = {
      general = {
        DisplayServer = "wayland";
        GreeterEnvironment = "QT_WAYLAND_SHELL_INTEGRATION=layer-shell";
      };
      wayland = { CompositorCommand = ""; };
    };
  };
}
