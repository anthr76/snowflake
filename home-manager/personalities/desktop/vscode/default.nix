{ pkgs, inputs, config, ...}:
{
  # TODO: See if we can just include in a overlay for vscode.
  home.packages = [ pkgs.helm-ls ];
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    extensions = with (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version).vscode-marketplace; [
        # Themes
        catppuccin.catppuccin-vsc
        thang-nm.catppuccin-perfect-icons
        # Language support
        golang.go
        hashicorp.terraform
        jnoortheen.nix-ide
        mrmlnc.vscode-json5
        ms-azuretools.vscode-docker
        ms-python.python
        redhat.ansible
        redhat.vscode-yaml
        tamasfe.even-better-toml
        helm-ls.helm-ls
        ms-vscode.makefile-tools
        grafana.vscode-jsonnet
        github.vscode-github-actions
        ms-vscode.cpptools-extension-pack
        unifiedjs.vscode-mdx
        ms-python.black-formatter
        nickgo.cuelang
        # Formatters
        esbenp.prettier-vscode
        darkriszty.markdown-table-prettify
        # Linters
        davidanson.vscode-markdownlint
        fnando.linter
        dbaeumer.vscode-eslint
        charliermarsh.ruff
        # Other
        gruntfuggly.todo-tree
        ionutvmi.path-autocomplete
        luisfontes19.vscode-swissknife
        ms-kubernetes-tools.vscode-kubernetes-tools
        editorconfig.editorconfig
        shd101wyy.markdown-preview-enhanced
        bierner.emojisense
        yzhang.markdown-all-in-one
        streetsidesoftware.code-spell-checker
        github.copilot
        mechatroner.rainbow-csv
        tobermory.es6-string-html
        bpruitt-goddard.mermaid-markdown-syntax-highlighting
        bashmish.es6-string-css
        github.vscode-pull-request-github
      ];
    userSettings = {
      "[go]".editor.defaultFormatter = "golang.go";
      "[go]".toolsManagement.autoUpdate = true;
      "[nix]".editor.defaultFormatter = "jnoortheen.nix-ide";
      "[terraform]".editor.defaultFormatter = "hashicorp.terraform";
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
        serverPath = "${pkgs.nixd}/bin/nixd";
        hiddenLanguageServerErrors = [
          "textDocument/definition"
        ];
        serverSettings = {
          nixd = {
            formatting = {
              command = "${pkgs.nixfmt-rfc-style}/bin/nixfmt";
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
      "workbench.iconTheme" = "catppuccin-perfect-macchiato";
      "extensions.autoUpdate" = false;
      update = {
        mode = "manual";
        showReleaseNotes = false;
      };
    };
  };
}
