{ pkgs, inputs, config, ...}:
{
  # TODO: See if we can just include in a overlay for vscode.
  home.packages = [ pkgs.helm-ls ];
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    extensions = let
      inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}) vscode-marketplace;
    in
      with vscode-marketplace; [
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
        # Formatters
        esbenp.prettier-vscode
        # Linters
        davidanson.vscode-markdownlint
        fnando.linter
        # Remote development
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        # Other
        gruntfuggly.todo-tree
        ionutvmi.path-autocomplete
        luisfontes19.vscode-swissknife
        ms-kubernetes-tools.vscode-kubernetes-tools
        shipitsmarter.sops-edit
      ];
    userSettings = {
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
      terminal.intergrated.inheritEnv = true;
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
      window = {
        commandCenter = false;
        newWindowDimensions = "maximized";
        restoreWindows = "none";
        titleBarStyle = "custom";
        autoDetectColorScheme = true;
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
    };
  };
}
