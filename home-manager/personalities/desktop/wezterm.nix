{
  pkgs,
  config,
  ...
}: {
  programs.wezterm = {
    enable = true;

    extraConfig = ''
      local wezterm = require 'wezterm'

      if not config then
        if wezterm.config_builder then
          config = wezterm.config_builder()
        else
          config = {}
        end
      end

      -- ========= Fonts =========
      config.font = wezterm.font_with_fallback({
        '${config.fontProfiles.monospace.family}',
        '${config.fontProfiles.icon.family}',
        '${config.fontProfiles.emoji.family}',
      })
      config.font_size = 16.0

      config.harfbuzz_features = {
        'zero=1',
        'calt=1',
        'liga=1',
        'clig=1',
        'ss01=1',
        'ss02=1',
        'ss03=1',
        'ss04=1',
        'ss05=1',
        -- 'ss06=1', -- <-- Causes issues with some variants
        'ss07=1',
        'ss08=1',
        'ss09=1',
        'ss10=1',
      }

      -- ========= UI =========
      config.hide_tab_bar_if_only_one_tab = true
      config.default_prog = { '${pkgs.fish}/bin/fish', '-l' }

      -- Thin I-Beam cursor, power-aware (blink on AC, steady on battery)
      config.cursor_thickness = 0.15

      config.keys = {
        {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
      }

      local function on_ac_power()
        for _, b in ipairs(wezterm.battery_info()) do
          if b.state == 'Charging' or b.state == 'Full' then
            return true
          end
        end
        return false
      end

      local function maybe_apply_cursor(window)
        local desired = on_ac_power() and 'BlinkingBar' or 'SteadyBar'
        local overrides = window:get_config_overrides() or {}
        if overrides.default_cursor_style ~= desired then
          overrides.default_cursor_style = desired
          window:set_config_overrides(overrides)
        end
      end

      -- No custom right-status text; we only use the event to flip the cursor
      wezterm.on('update-right-status', function(window, _)
        maybe_apply_cursor(window)
      end)

      config.default_cursor_style = on_ac_power() and 'BlinkingBar' or 'SteadyBar'

      return config
    '';
  };

  catppuccin.wezterm = {
    apply = true;
    enable = true;
  };
}
