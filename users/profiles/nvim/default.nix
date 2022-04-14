{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
       plenary-nvim
       telescope-nvim
       nvim-lspconfig
       lspsaga-nvim
       cmp-nvim-lsp
       #cmp-buffer
       #cmp-path
       #cmp-cmdline
       #cmp-vsnip
       vim-vsnip
       nvim-treesitter
       lualine-nvim
    ];
   };
   # hehe
   xdg.configFile = {
     "nvim/lua/init.lua".source = ./init.lua;
   };
}
