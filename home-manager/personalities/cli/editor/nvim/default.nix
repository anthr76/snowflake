{ config, pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "8fe945f07aebf8dd2006e7cb3f89c200e0e4adef";
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    # extraLuaConfig = ''
    # vim.opt.rtp:append("${config.xdg.configHome}/nvim/lua/user")
    # '';
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
    userConfig = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      recursive = true;
      target = "nvim/lua/user";
      source = ./lua;
    };
    astronvim = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      recursive = true;
      target = "astronvim";
      source = astroNvimSource;
    };
  };
  home.sessionVariables = {
    NVIM_APPNAME = "astronvim";
  };
}
