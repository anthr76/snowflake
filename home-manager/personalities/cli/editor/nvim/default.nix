{ config, pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "v3.33.4";
    sha256 = "utGG1U9p3a5ynRcQys1OuD5J0LjkIQipD0TX8zW66/4=";
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    extraLuaConfig = ''
    vim.opt.rtp:append("${config.xdg.configHome}/nvim/lua/user")
    '';
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
