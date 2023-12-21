{ pkgs, ... }:
{
  home.sessionVariables = {
    EDITOR = "lvim";
  };
  home.packages = with pkgs; [ lunarvim ];
  home.shellAliases = {
    "nvim" = "lvim";
    "vim" = "lvim";
    "vi" = "lvim";
  };
  xdg.configFile = {
    init = {
      recursive = false;
      target = "lvim/config.lua";
      text = /* lua */ ''

          if not configs.helm_ls then
            configs.helm_ls = {
              default_config = {
                cmd = {"helm_ls", "serve"},
                filetypes = {'helm'},
                root_dir = function(fname)
                  return util.root_pattern('Chart.yaml')(fname)
                end,
              },
            }
          end

          lspconfig.helm_ls.setup {
            filetypes = {"helm"},
            cmd = {"helm_ls", "serve"},
          }
        vim.cmd([[
          autocmd BufRead,BufNewFile */templates/*.y*ml,*/templates/*.tpl,*.gotmpl,helmfile*.yml set ft=helm
          autocmd BufRead,BufNewFile */templates/*.y*ml,*/templates/*.tpl,*.gotmpl,helmfile*.yml LspStop yammls
        ]])
        lvim.plugins = {
          {
            "towolf/vim-helm",
            event = "VeryLazy",
          },
          {
            "folke/todo-comments.nvim,"
            event = "BufReadPost",
            dependencies = { "nvim-lua/plenary.nvim" },
            opts = {
              -- your configuration comes here
              -- or leave it empty to use the default settings
              -- refer to the configuration section below
            }
          },
          {
            "andweeb/presence.nvim",
            event = "VeryLazy",
            opts = {
            }
          },
          {
            "zbirenbaum/copilot.lua",
            cmd = "Copilot",
            event = "InsertEnter",
            config = function()
              require("copilot").setup({})
            end
          },
        }
      '';
    };
  };
}
