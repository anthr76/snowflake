{ config, pkgs, ...}:
{
  programs.wezterm = {
    enable = true;
    extraConfig = /* lua */ ''
      return {
        font = wezterm.font("${config.fontProfiles.monospace.family}"),
        font_size = 12.0,
        window_close_confirmation = "NeverPrompt",
        hide_mouse_cursor_when_typing = false,
        automatically_reload_config = true,
      }
    '';
  };
}
