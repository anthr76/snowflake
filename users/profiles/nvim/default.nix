{ config, pkgs, ... }: {
  # TODO: Get a grip on the organization of this/
  imports = [ ./ui.nix ./lsp.nix ./syntax.nix ];

  programs.neovim = {
    enable = true;
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
      docker-ls
      nodePackages.vscode-json-languageserver
      nodePackages.bash-language-server
      tree-sitter
      terraform-ls
      rnix-lsp
      nodePackages.yaml-language-server
    ];
  };
  home.sessionVariables.EDITOR = "nvim";

}
