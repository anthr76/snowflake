{
  pkgs,
  config,
  ...
}: {
  # TODO: See if we can just include in a overlay for vscode.
  home.packages = [
    pkgs.helm-ls
    pkgs.github-mcp-server
  ];
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = pkgs.nix4vscode.forVscode [
        "catppuccin.catppuccin-vsc"
        "thang-nm.catppuccin-perfect-icons"
        "golang.go"
        "jnoortheen.nix-ide"
        "mrmlnc.vscode-json5"
        "ms-azuretools.vscode-docker"
        # TODO: Failing to build in nixpkgs at the moment
        # "ms-python.python"
        # "ms-python.black-formatter"
        "redhat.ansible"
        "redhat.vscode-yaml"
        "tamasfe.even-better-toml"
        "helm-ls.helm-ls"
        "ms-vscode.makefile-tools"
        "grafana.vscode-jsonnet"
        "github.vscode-github-actions"
        "ms-vscode.cpptools-extension-pack"
        "unifiedjs.vscode-mdx"
        "nickgo.cuelang"
        "esbenp.prettier-vscode"
        "darkriszty.markdown-table-prettify"
        "davidanson.vscode-markdownlint"
        "fnando.linter"
        "dbaeumer.vscode-eslint"
        "charliermarsh.ruff"
        "gruntfuggly.todo-tree"
        "ionutvmi.path-autocomplete"
        "luisfontes19.vscode-swissknife"
        "ms-kubernetes-tools.vscode-kubernetes-tools"
        "editorconfig.editorconfig"
        "shd101wyy.markdown-preview-enhanced"
        "bierner.emojisense"
        "yzhang.markdown-all-in-one"
        "streetsidesoftware.code-spell-checker"
        "mechatroner.rainbow-csv"
        "tobermory.es6-string-html"
        "bpruitt-goddard.mermaid-markdown-syntax-highlighting"
        "bashmish.es6-string-css"
        "github.vscode-pull-request-github"
        "tilt-dev.tiltfile"
        "vscjava.vscode-java-pack"
        "mathiasfrohlich.kotlin"
        "fwcd.kotlin"
        "github.copilot-chat"
        "github.copilot"
        "eamodio.gitlens"
      ];
      userSettings = {
        "[go]".editor.defaultFormatter = "golang.go";
        "[go]".toolsManagement.autoUpdate = true;
        "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
        "[terraform]".editor.defaultFormatter = "hashicorp.terraform";
        kotlin.java.home = "${pkgs.jdk}/lib/openjdk";
        kotlin.languageServer.path = "${pkgs.kotlin-language-server}/bin/kotlin-language-server";
        kotlin.debugAdapter.path = "${pkgs.kotlin-debug-adapter}/bin/kotlin-debug-adapter";
        cSpell.enabled = false;
        git = {
          autofetch = true;
          confirmSync = false;
        };
        linter = {
          linters = {
            yamllint = {
              configFiles = [
                ".yamllint.yml"
                ".yamllint.yaml"
                ".yamllint"
                ".ci/yamllint/.yamllint.yaml"
              ];
            };
          };
        };
        nix = {
          enableLanguageServer = true;
          formatterPath = "${pkgs.alejandra}/bin/alejandra";
          serverPath = "${pkgs.nil}/bin/nil";
          hiddenLanguageServerErrors = [
            "textDocument/definition"
          ];
          serverSettings = {
            nil = {
              formatting = {
                command = ["${pkgs.alejandra}/bin/alejandra"];
              };
              nix = {
                maxMemoryMB = 8096;
                flake = {
                  autoEvalInputs = true;
                };
              };
            };
          };
        };
        path-autocomplete = {
          triggerOutsideStrings = true;
        };
        todo-tree = {
          highlights = {
            useColourScheme = true;
          };
          tree = {
            expanded = true;
          };
        };
        editor = {
          bracketPairColorization = {
            enabled = true;
          };
          defaultFormatter = "esbenp.prettier-vscode";
          fontFamily = "${config.fontProfiles.monospace.family}";
          fontLigatures = "'calt', 'liga', 'ss06'";
          guides = {
            bracketPairs = true;
            bracketPairsHorizontal = true;
            highlightActiveBracketPair = true;
          };
          stickyScroll = {
            enabled = true;
          };
          tabSize = 2;
        };
        "terminal.intergrated.inheritEnv" = true;
        explorer = {
          compactFolders = false;
          confirmDelete = false;
          confirmDragAndDrop = false;
        };
        files = {
          associations = {};
          autoSave = "onFocusChange";
          eol = "\n";
          insertFinalNewline = true;
          trimFinalNewlines = true;
          trimTrailingWhitespace = true;
        };
        vs-kubernetes = {
          "vs-kubernetes.crd-code-completion" = "disabled";
        };
        window = {
          commandCenter = false;
          newWindowDimensions = "maximized";
          restoreWindows = "none";
          titleBarStyle = "custom";
          autoDetectColorScheme = false;
        };
        workbench = {
          colorTheme = "Catppuccin Mocha";
          iconTheme = "catppuccin-perfect-macchiato";
          sideBar = {
            location = "left";
          };
          startupEditor = "newUntitledFile";
          tree = {
            renderIndentGuides = "none";
          };
        };
        chat = {
          mcp = {
            enabled = true;
          };
        };
        mcp = {
          inputs = [
            {
              type = "promptString";
              id = "github_token";
              description = "GitHub Personal Access Token";
              password = true;
            }
          ];
          servers = {
            "github" = {
              type = "stdio";
              command = "${pkgs.github-mcp-server}/bin/github-mcp-server";
              args = [];
              env = {
                "GITHUB_PERSONAL_ACCESS_TOKEN" = "\${input:github_token}";
              };
            };
          };
        };
        "workbench.iconTheme" = "catppuccin-perfect-macchiato";
        "extensions.autoUpdate" = false;
        update = {
          mode = "manual";
          showReleaseNotes = false;
        };
      };
    };
  };
}
