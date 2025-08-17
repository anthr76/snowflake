{ pkgs, ... }: {
  home.packages = with pkgs; [ fzf fd ];
  programs.fish = {
    enable = true;
    shellAliases = {
      yssh = "${pkgs.openssh}/bin/ssh-add -s ${pkgs.yubico-piv-tool}/lib/libykcs11.so";
      tssh = if pkgs.stdenv.isLinux then "${pkgs.openssh}/bin/ssh-add -s ${pkgs.tpm2-pkcs11}/lib/libtpm2_pkcs11.so" else "echo Not supported.";
    };
    functions = {
      fish_greeting = "";
      __fish_command_not_found_handler = {
        body = "__fish_default_command_not_found_handler $argv[1]";
        onEvent = "fish_command_not_found";
      };
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
    };
  };
  catppuccin.fish.enable = true;
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
  catppuccin.fzf.enable = true;

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
      filter_mode_shell_up_key_binding = "directory";
      style = "compact";
    };
  };
  catppuccin.atuin.enable = true;

}
