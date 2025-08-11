{ pkgs,config, ...}: {
  programs.wezterm = {
    enable = true;
    # TODO: https://github.com/NixOS/nixpkgs/issues/336069
    extraConfig = ''
      local wezterm = require 'wezterm'
      config.font = wezterm.font '${config.fontProfiles.monospace.family}'
      config.font_size = 16.0
      config.window_decorations = "RESIZE"
      config.hide_tab_bar_if_only_one_tab = trye
      config.default_prog = { "${pkgs.fish}/bin/fish", "-l" }
      return config
    '';
  };
  catppuccin.wezterm = {
    apply = true;
    enable = true;
  };
}
