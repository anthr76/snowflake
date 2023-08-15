{ config, pkgs, ...}:
{
  programs.wezterm = {
    enable = true;
    package = pkgs.unstable.wezterm;
    extraConfig = /* lua */ ''
      local wayland_gnome = require 'wayland_gnome'
      wayland_gnome.apply_to_config(config)
      return {
        font = wezterm.font("${config.fontProfiles.monospace.family}"),
        font_size = 12.0,
        window_close_confirmation = "NeverPrompt",
        hide_mouse_cursor_when_typing = false,
        automatically_reload_config = true,
        hide_tab_bar_if_only_one_tab = true,
        visual_bell = {
            fade_in_function = 'Linear',
            fade_in_duration_ms = 40,
            fade_out_function = 'EaseOut',
            fade_out_duration_ms = 150,
        },
      }
    '';
  };
  xdg.configFile = {
    extraConfig = {
      target = "wezterm/wayland_gnome.lua";
      # TODO: This assumes gnome so when it isn't just gnome fix this.
      # https://github.com/wez/wezterm/issues/3334#issuecomment-1510393277
      text = /* lua */  ''
        local wezterm = require 'wezterm'
        local mod = {}

        local function gsettings(key)
          return wezterm.run_child_process({"gsettings", "get", "org.gnome.desktop.interface", key})
        end

        function mod.apply_to_config(config)
          if wezterm.target_triple ~= "x86_64-unknown-linux-gnu" then
            -- skip if not running on linux
            return
          end
          local success, stdout, stderr = gsettings("cursor-theme")
          if success then
            config.xcursor_theme = stdout:gsub("'(.+)'\n", "%1")
          end

          local success, stdout, stderr = gsettings("cursor-size")
          if success then
            config.xcursor_size = tonumber(stdout)
          end

          config.enable_wayland = true

          if config.enable_wayland and os.getenv("WAYLAND_DISPLAY") then
            local success, stdout, stderr = gsettings("text-scaling-factor")
            if success then
              config.font_size = (config.font_size or 10.0) * tonumber(stdout)
            end
          end

        end

        return mod
      '';
    };
  };
}
