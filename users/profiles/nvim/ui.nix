{ pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [{
    plugin = lualine-nvim;
    config = # vim
      ''
        lua << EOF
          require('lualine').setup{
            options = {
              theme = 'ayu_mirage'
            }
          }
        EOF
      '';
  }

    ];
}
