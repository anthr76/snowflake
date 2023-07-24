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
    nvim = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      source = pkgs.fetchFromGitHub {
        owner = "AstroNvim";
        repo = "AstroNvim";
        rev = "8fe945f07aebf8dd2006e7cb3f89c200e0e4adef";
        sha256 = "ELEmU6fyC/QzIhV8LmXGB65uEZrmHabIW79xSQiLu6I=";
      };
    };
  };
}
