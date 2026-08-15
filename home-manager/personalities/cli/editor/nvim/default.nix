{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [inputs.nvf.homeManagerModules.default];

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
      };
      vim.assistant.copilot.enable = lib.mkForce true;
      vim.statusline.lualine.setupOpts.options.theme = "catppuccin-nvim";
      vim.clipboard = {
        enable = true;
        registers = "unnamedplus";
        providers.wl-copy.enable = pkgs.stdenv.hostPlatform.isLinux;
      };
    };
  };
}
