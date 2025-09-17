{
  pkgs,
  inputs,
  config,
  ...
}: {
  programs.claude-code = {
    enable = true;
    package = inputs.nix-ai-tools.packages.${pkgs.system}.claude-code;
    # TODO: Auth via env var https://github.com/github/github-mcp-server#environment-variables-recommended
    mcpServers = config.programs.vscode.profiles.default.userMcp.servers;

  };
  programs.codex = {
    enable = true;
    package = inputs.nix-ai-tools.packages.${pkgs.system}.codex;
    # TODO: Transform to TOML from VSCode?
    settings = {
      mcp_servers = {
        nixos = {
          type = "stdio";
          command = "nix";
          args = ["run" "github:utensils/mcp-nixos" "--"];
        };
        gk = {
          type = "stdio";
          command = "${pkgs.gk-cli}/bin/gk";
          args = ["mcp"];
        };
        mcp-k8s-go = {
          type = "stdio";
          command = "${pkgs.mcp-k8s-go}/bin/mcp-k8s-go";
          env = {
            KUBECONFIG = "\${env:KUBECONFIG}";
          };
        };
      };
    };
  };
  home.packages = [
    inputs.nix-ai-tools.packages.${pkgs.system}.catnip
  ];
}
