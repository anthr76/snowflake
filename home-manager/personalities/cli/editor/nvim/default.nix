{ config, pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "v3.36.5";
    sha256 = "XEhN2tNSQPYlFc3MgWgFW8hc9jPHHlwuOmVY8lY2EXg=";
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
      pkgs.unstable.rustc
      pkgs.nodejs
      pkgs.libstdcxx5
      pkgs.gnumake
      pkgs.gcc
    ];

  };
  xdg.configFile = {
    astronvim = {
      recursive = true;
      target = "astronvim";
      source = astroNvimSource;
    };
    userConfig = {
      recursive = true;
      target = "astronvim/lua/user";
      source = ./lua;
    };
  };
  home.sessionVariables = {
    NVIM_APPNAME = "astronvim";
  };
}
