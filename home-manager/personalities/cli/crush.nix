{pkgs, ...}: {
  # WIP
  programs.crush = {
    enable = false;

    # Language Server configurations
    lsp = {
      nix = {
        command = "${pkgs.nil}/bin/nil";
      };
      go = {
        command = "${pkgs.gopls}/bin/gopls";
      };
      terraform = {
        command = "${pkgs.terraform-ls}/bin/terraform-ls";
        args = ["serve"];
      };
      tilt = {
        command = "${pkgs.tilt}/bin/tilt";
        args = ["lsp" "start"];
      };
      yaml = {
        command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
        args = ["--stdio"];
      };
    };

    # Model Context Protocol configurations
    mcp = {
      nixos = {
        type = "stdio";
        command = "${pkgs.nix}/bin/nix";
        args = ["run" "github:utensils/mcp-nixos" "--"];
      };
      github = {
        type = "http";
        url = "https://api.githubcopilot.com/mcp/";
      };
    };

    # Additional configuration
    extraConfig = {
      # Add any additional Crush configuration here
      # For example:
      # models = {
      #   large = {
      #     model = "gpt-4o";
      #     provider = "openai";
      #   };
      # };
    };
  };
}
