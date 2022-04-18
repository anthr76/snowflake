{ pkgs, ... }: {
  programs.neovim.plugins = with pkgs.vimPlugins; [

    # LSP
    {
      plugin = nvim-lspconfig;
      config = # vim
        ''
          lua << EOF
            local nvim_lsp = require('lspconfig')
            local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
            local servers = { 'ansiblels', 'bashls', 'dockerls', 'jsonls', 'gopls', 'puppet', 'terraformls', 'yamlls', 'rnix' }
            for _, lsp in ipairs(servers) do
              nvim_lsp[lsp].setup{ capabilities = capabilities }
            end
          EOF
        '';
    }
    {
      plugin = lspsaga-nvim;
      config = # vim
        ''
          lua << EOF
            require('lspsaga').init_lsp_saga()
          EOF
        '';
    }
    {
      plugin = (nvim-treesitter.withPlugins (plugins:
        with pkgs.tree-sitter-grammars; [
          tree-sitter-nix
          # TODO: rust and others only on dev machines
          tree-sitter-c
          tree-sitter-comment
          tree-sitter-lua
          tree-sitter-markdown
          tree-sitter-ocaml
          tree-sitter-rust
          tree-sitter-vim
        ]));
      config = # vim
        ''
          lua << EOF
            require('nvim-treesitter.configs').setup {
              highlight = {
                enable = true,
                disable = {},
              },
              indent = {
                enable = false,
                disable = {},
              },
            }
          EOF
        '';
    }
    # Completions
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    cmp-cmdline
    cmp-vsnip
    vim-vsnip
    {
      plugin = nvim-cmp;
      config = # vim
        ''
          lua << EOF
            local cmp = require'cmp'
            
            cmp.setup({
              snippet = {
                -- REQUIRED - you must specify a snippet engine
                expand = function(args)
                  vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
                  -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
                  -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
                  -- require'snippy'.expand_snippet(args.body) -- For `snippy` users.
                end,
              },
              mapping = {
                ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
                ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
                ['<C-e>'] = cmp.mapping({
                  i = cmp.mapping.abort(),
                  c = cmp.mapping.close(),
                }),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
              },
              sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                { name = 'vsnip' }, -- For vsnip users.
                -- { name = 'luasnip' }, -- For luasnip users.
                -- { name = 'ultisnips' }, -- For ultisnips users.
                -- { name = 'snippy' }, -- For snippy users.
              }, {
                { name = 'buffer' },
              })
            })
            -- Use buffer source for `/` (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline('/', {
              sources = {
                { name = 'buffer' }
              }
            })
            -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
            cmp.setup.cmdline(':', {
              sources = cmp.config.sources({
                { name = 'path' }
              }, {
                { name = 'cmdline' }
              })
            })
          EOF
        '';
    }
  ];
}
