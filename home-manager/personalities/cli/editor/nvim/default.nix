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
    ];

  };
  xdg.configFile = {
    # Not Very Idempotent yet :(
    nvim = {
      onChange = "${pkgs.neovim}/bin/nvim --headless +quitall";
      source = pkgs.fetchFromGitHub {
        owner = "AstroNvim";
        repo = "AstroNvim";
        rev = "346c19a0ed1473a64b7495c26ade14760c41b7c7";
        sha256 = "6UMIb7d+UADbf6p5FJU2AArNDk7Ur9Lzb+WykQkNB/I=";
      };
    };
  };
}
