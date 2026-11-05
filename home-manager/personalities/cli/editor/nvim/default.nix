{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [inputs.nvf.homeManagerModules.default];

  # nvf has no `defaultEditor` option of its own, so set the variables directly.
  # `vim`/`vi` come from nvf's viAlias/vimAlias, which the imported default
  # configuration turns on.
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # nvf's curated "default" configuration -- the module nvf's default package is
  # built from, imported directly so we track upstream instead of hand-picking a
  # plugin list. Catppuccin (mocha) is the theme out of the box. We deliberately
  # avoid the `maximal` variant: its extra plugins (otter, harper, scrollbar, ...)
  # currently break against the mid-migration nvim-treesitter in nixpkgs-unstable
  # (`nvim-treesitter.ts_utils` was removed), and it pulls a Darwin-broken sass
  # language server. Default sidesteps both.
  programs.nvf = {
    enable = true;
    settings = {
      imports = [(import "${inputs.nvf}/configuration.nix" false)];

      # Default only ships nix + markdown, and gates the rest off explicitly
      # (`isMaximal`), so mkForce is needed to turn the ones we use back on.
      vim.languages = {
        go.enable = lib.mkForce true; # gopls + DAP
        helm.enable = lib.mkForce true; # helm-ls
        yaml.enable = lib.mkForce true; # backs helm values
        json.enable = lib.mkForce true; # vscode-json-language-server + jsonfmt
        # Both formatters are registered; the conditions below pick one per file.
        nix.format.type = ["alejandra" "nixfmt"];
      };

      # Format Nix with nixfmt inside a nixpkgs checkout (its CI enforces nixfmt
      # and rejects anything else) and with Alejandra everywhere else. Detection:
      # the enclosing git root contains pkgs/top-level/all-packages.nix.
      vim.formatter.conform-nvim.setupOpts.formatters = let
        inNixpkgs = ''
          local root = vim.fs.root(ctx.dirname, ".git")
          local in_nixpkgs = root ~= nil
            and vim.uv.fs_stat(root .. "/pkgs/top-level/all-packages.nix") ~= nil
        '';
      in {
        alejandra.condition = lib.generators.mkLuaInline ''
          function(self, ctx)
            ${inNixpkgs}
            return not in_nixpkgs
          end
        '';
        nixfmt.condition = lib.generators.mkLuaInline ''
          function(self, ctx)
            ${inNixpkgs}
            return in_nixpkgs
          end
        '';
      };
      vim.assistant.copilot.enable = lib.mkForce true;
      # nvf's own `configuration.nix` still sets the pre-2026-09-04 `lualine.theme`,
      # which nvf's `batchRenameOptions` now forwards onto this same option as
      # "catppuccin". mkForce breaks the resulting definition conflict.
      vim.statusline.lualine.setupOpts.options.theme = lib.mkForce "catppuccin-nvim";
      vim.clipboard = {
        enable = true;
        registers = "unnamedplus";
        providers.wl-copy.enable = pkgs.stdenv.hostPlatform.isLinux;
      };

      # nvf enables neo-tree but ships no binding for it -- it is lazy-loaded on
      # the `Neotree` command, which this triggers.
      vim.keymaps = [
        {
          key = "<leader>e";
          mode = "n";
          silent = true;
          action = "<cmd>Neotree toggle<CR>";
          desc = "Toggle file explorer";
        }
      ];
    };
  };
}
