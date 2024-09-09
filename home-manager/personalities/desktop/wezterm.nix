{ pkgs,config, ...}: {
  programs.wezterm = {
    enable = true;
    # TODO: https://github.com/NixOS/nixpkgs/issues/336069
    extraConfig = ''
      return {
        front_end = "WebGpu",
        enable_wayland = false,
        font = wezterm.font("${config.fontProfiles.monospace.family}"),
        font_size = 16.0,
        color_scheme = "Catppuccin Mocha",
        hide_tab_bar_if_only_one_tab = true,
        default_prog = { "${pkgs.fish}/bin/fish", "-l" },
      }
    '';
  };
}
