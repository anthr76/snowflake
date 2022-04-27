{ config, pkgs, ... }: {
  # TODO: Get a grip on the organization of this/
  imports = [ ./ui.nix ./lsp.nix ];

  programs.neovim = {
    enable = true;
    package = pkgs.channels.latest.neovim-unwrapped;
    vimAlias = true;
    viAlias = true;
    # https://github.com/nix-community/home-manager/issues/1907
    # Solved in unstable.
    extraConfig = builtins.concatStringsSep "\n" [
      ''
        luafile ${builtins.toString ./configure.lua}
      ''
    ];
    extraPackages = with pkgs; [
      pkgs.channels.latest.docker-ls
      pkgs.channels.latest.nodePackages.vscode-json-languageserver
      pkgs.channels.latest.nodePackages.bash-language-server
      pkgs.channels.latest.tree-sitter
      pkgs.channels.latest.terraform-ls
      pkgs.channels.latest.rnix-lsp
      pkgs.channels.latest.nodePackages.yaml-language-server
    ];
  };
  home.sessionVariables.EDITOR = "nvim";

}
