{ lib,config,pkgs,inputs, ...}:{
  imports = [
    inputs.hyprland.homeManagerModules.default
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      general = {
        gaps_in = 15;
        gaps_out = 20;
        border_size = 2.7;
      };
      input = {
        kb_layout = "en,us";
        touchpad.disable_while_typing = true;
      };
      dwindle.split_width_multiplier = 1.35;

      animations = {
        enabled = true;
      };

    };
  };
}
