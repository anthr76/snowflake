{ config, pkgs, ... }: {
  # TODO: Get a grip on the organization of this/
  imports = [ ./ui.nix ./lsp.nix ./syntax.nix ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    extraConfig = # vim
      ''
        "Use truecolor
        set termguicolors
        "Reload automatically
        set autoread
        "Clipboard
        set clipboard=unnamedplus
        "Fix nvim size according to terminal
        "(https://github.com/neovim/neovim/issues/11330)
        autocmd VimEnter * silent exec "!kill -s SIGWINCH" getpid()
        "Scroll up and down
        nmap <C-j> <C-e>
        nmap <C-k> <C-y>
      '';
    #    plugins = with pkgs.vimPlugins; [
    #      tree-sitter-grammars.tree-sitter-nix
    #      {
    #        plugin = which-key-nvim;
    #        config = /* lua */ ''
    #          lua require('which-key').setup{}
    #        '';
    #      }
    #    ];
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
