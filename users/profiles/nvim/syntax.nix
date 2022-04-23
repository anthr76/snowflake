{ pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [ haskell-vim ];
}
