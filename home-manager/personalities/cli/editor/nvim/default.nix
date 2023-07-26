{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
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
    # Not Very Idempotent yet :(
    astrovim = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      target = "nvim/astrovim";
      source = pkgs.fetchFromGitHub {
        owner = "AstroNvim";
        repo = "AstroNvim";
        rev = "96ddbcc391b6ef5fa58c9d6ce9a8334e86b65f20";
        sha256 = "LVaeoR34nwQEZXpNryPLh4RRVQvWuyq3tAGaW3iYHow=";
      };
    };
    lua = {
      source = ./lua;
      recursive = true;
      target = "nvim/lua/user";
    };
  };
  home.sessionVariables = {
    NVIM_APPNAME = "nvim/astrovim";
  };
}
