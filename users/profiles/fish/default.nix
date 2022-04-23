{ pkgs, lib, ... }: {
  home.packages = with pkgs; [ fzf fd bat ];
  programs.fish = {
    enable = true;
    shellAliases = {
      yssh = "ssh-add -s ${pkgs.yubico-piv-tool}/lib/libykcs11.so";
      nixdev = "nix develop --command fish";
    };
    functions = {
      fish_greeting = "";
      __fish_command_not_found_handler = {
        body = "__fish_default_command_not_found_handler $argv[1]";
        onEvent = "fish_command_not_found";
      };
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
    };
    plugins = [{
      name = "fzf";
      src = pkgs.fetchFromGitHub {
        owner = "PatrickF1";
        repo = "fzf.fish";
        rev = "v8.3";
        sha256 = "eSNUqvKXTxcuvICxo8BmVWL1ESXQuU7VhOl7aONrhwM=";
      };
    }];
  };
}
