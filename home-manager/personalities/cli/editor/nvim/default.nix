{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
  xdg.configFile."nvim/.neoconf.json".text = /* json */ ''
    {
      "neodev": {
        "library": {
          "enabled": true,
          "plugins": true
        }
      },
      "neoconf": {
        "plugins": {
          "lua_ls": {
            "enabled": true
          }
        }
      },
      "lspconfig": {
        "lua_ls": {
          "Lua.format.enable": false
        }
      }
    }
  '';
  xdg.configFile."nvim/.stylua.toml".text = /* toml */ ''
    column_width = 120
    line_endings = "Unix"
    indent_type = "Spaces"
    indent_width = 2
    quote_style = "AutoPreferDouble"
    call_parentheses = "None"
    collapse_simple_statement = "Always"
  '';
  xdg.configFile."nvim/init.lua".text = /* lua */ ''
    -- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
    -- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
    local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
    if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
      -- stylua: ignore
      vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
    end
    vim.opt.rtp:prepend(lazypath)

    -- validate that lazy is available
    if not pcall(require, "lazy") then
      -- stylua: ignore
      vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
      vim.fn.getchar()
      vim.cmd.quit()
    end

    require "lazy_setup"
    require "polish"
  '';
  xdg.configFile."nvim/.neovim.yml".text = /* yaml */ ''
    ---
    base: lua51
    globals:
      vim:
        any: true
  '';
  xdg.configFile."nvim/.selene.toml".text = /* toml */ ''
    std = "neovim"
    [rules]
    global_usage = "allow"
    if_same_then_else = "allow"
    incorrect_standard_library_use = "allow"
    mixed_table = "allow"
    multiple_statements = "allow"
  '';
  xdg.configFile = {
    userConfig = {
      recursive = true;
      target = "nvim/lua";
      source = ./lua;
    };
  };
}
