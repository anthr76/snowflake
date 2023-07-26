{ config, pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "96ddbcc391b6ef5fa58c9d6ce9a8334e86b65f20";
    sha256 = "LVaeoR34nwQEZXpNryPLh4RRVQvWuyq3tAGaW3iYHow=";
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
