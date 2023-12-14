{ pkgs, ... }:
let
  astroNvimSource = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "v3.38.0";
    sha256 = "cxzs52iIkCWkzLk5uoYunbyiher+6ZTyACUT7vxQN6Y=";
  };
  parsers = pkgs.tree-sitter.withPlugins (_: pkgs.tree-sitter.allGrammars);
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    plugins = [
      pkgs.vimPlugins.nvim-treesitter
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
      pkgs.go
      pkgs.clangStdenv
      pkgs.gccStdenv
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
    parsers = {
      recursive = false;
      target = "astronvim/lua/user/parsers/init.lua";
      text = /* lua */ ''
        vim.opt.runtimepath:append("${parsers}")
      '';
    }
  };
  home.sessionVariables = {
    NVIM_APPNAME = "astronvim";
  };
}
