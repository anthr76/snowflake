{ config, pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "v3.34.0";
    sha256 = "ELEmU6fyC/QzIhV8LmXGB65uEZrmHabIW79xSQiLu6I=";
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    plugins = [
      pkgs.vimPlugins.nvim-treesitter.withAllGrammars
    ];
    # https://astronvim.com/#-requirements
    extraPackages = [
      pkgs.nerdfonts
      pkgs.lazygit
      pkgs.tree-sitter
      pkgs.ripgrep
      pkgs.gdu
      pkgs.bottom
      pkgs.cargo
      pkgs.nodejs
      pkgs.libstdcxx5
    ];

  };
  xdg.configFile = {
    astronvim = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      recursive = true;
      target = "astronvim";
      source = astroNvimSource;
    };
    userConfig = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      recursive = true;
      target = "astronvim/lua/user";
      source = ./lua;
    };
  };
  home.sessionVariables = {
    NVIM_APPNAME = "astronvim";
  };
}
