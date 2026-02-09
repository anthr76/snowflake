{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib; let
  cfg = config.programs.crush;

  lspConfigType = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Command to execute for the LSP server.";
        example = "gopls";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Arguments to pass to the LSP server command.";
        example = ["--stdio"];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables to set for the LSP server.";
        example = {GOTOOLCHAIN = "go1.24.5";};
      };

      options = mkOption {
        type = types.attrs;
        default = {};
        description = "LSP server-specific configuration options.";
      };

      filetypes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "File types this LSP server handles.";
        example = ["go" "mod"];
      };

      disabled = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this LSP server is disabled.";
      };
    };
  };

  mcpConfigType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum ["stdio" "http" "sse"];
        default = "stdio";
        description = "Type of MCP connection.";
      };

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to execute for stdio MCP servers.";
        example = "node";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Arguments to pass to the MCP server command.";
        example = ["/path/to/mcp-server.js"];
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables to set for the MCP server.";
        example = {NODE_ENV = "production";};
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "URL for HTTP or SSE MCP servers.";
        example = "https://example.com/mcp/";
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "HTTP headers for HTTP/SSE MCP servers.";
        example = {Authorization = "$(echo Bearer $EXAMPLE_MCP_TOKEN)";};
      };

      disabled = mkOption {
        type = types.bool;
        default = false;
        description = "Whether this MCP server is disabled.";
      };

      timeout = mkOption {
        type = types.int;
        default = 15;
        description = "Timeout in seconds for MCP server connections.";
      };
    };
  };
in {
  options.programs.crush = {
    enable = mkEnableOption "Crush, an AI-powered assistant";

    package = mkOption {
      type = types.package;
      default = inputs.llm-agents.packages.${pkgs.system}.crush;
      defaultText = literalExpression "inputs.llm-agents.packages.\${pkgs.system}.crush";
      description = "The Crush package to install.";
    };

    lsp = mkOption {
      type = types.attrsOf lspConfigType;
      default = {};
      description = "Language Server Protocol configurations.";
      example = literalExpression ''
        {
          go = {
            command = "gopls";
            env = { GOTOOLCHAIN = "go1.24.5"; };
          };
          typescript = {
            command = "typescript-language-server";
            args = ["--stdio"];
          };
          nix = {
            command = "nil";
          };
        }
      '';
    };

    mcp = mkOption {
      type = types.attrsOf mcpConfigType;
      default = {};
      description = "Model Context Protocol server configurations.";
      example = literalExpression ''
        {
          filesystem = {
            type = "stdio";
            command = "node";
            args = ["/path/to/mcp-server.js"];
            env = { NODE_ENV = "production"; };
          };
          github = {
            type = "http";
            url = "https://example.com/mcp/";
            headers = { Authorization = "$(echo Bearer $EXAMPLE_MCP_TOKEN)"; };
          };
          streaming-service = {
            type = "sse";
            url = "https://example.com/mcp/sse";
            headers = { API-Key = "$(echo $API_KEY)"; };
          };
        }
      '';
    };

    extraConfig = mkOption {
      type = types.attrs;
      default = {};
      description = "Additional configuration options for Crush.";
      example = literalExpression ''
        {
          models = {
            large = {
              model = "gpt-4o";
              provider = "openai";
            };
          };
          providers = {
            openai = {
              api_key = "$OPENAI_API_KEY";
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    # Create configuration file
    home.file.".config/crush/crush.json" = mkIf (cfg.lsp != {} || cfg.mcp != {} || cfg.extraConfig != {}) {
      text = builtins.toJSON (
        {
          "$schema" = "https://charm.land/crush.json";
        }
        // (optionalAttrs (cfg.lsp != {}) {lsp = cfg.lsp;})
        // (optionalAttrs (cfg.mcp != {}) {mcp = cfg.mcp;})
        // cfg.extraConfig
      );
    };
  };
}
