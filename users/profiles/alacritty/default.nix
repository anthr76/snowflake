{ config, pkgs, ... }:

{
  home.sessionVariables = { TERMINAL = "alacritty"; };
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    settings = {
      live_config_reload = false;
      env = {
          TERM = "xterm-256color";
        };
      font = {
        size = 11.0;
        normal.family = "Fira Code Nerd Font";
      };
      window = { dynamic_title = true; };
    };
  };
}
