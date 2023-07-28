{ config, pkgs, ...}:
{
  programs.wezterm = {
    enable = true;
    extraConfig = /* lua */ ''
      return {
        font = wezterm.font("${config.fontProfiles.monospace.family}"),
        font_size = 12.0,
        window_close_confirmation = "NeverPrompt",
      }
    '';
  };
}
