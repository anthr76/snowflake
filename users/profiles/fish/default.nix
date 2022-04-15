{pkgs, lib, ...}: {

  programs.fish = {
    enable = true;
    interactiveShellInit = 
      ''
        set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/yubikey-agent/yubikey-agent.sock"
      '';
    functions = {
      fish_greeting = "";
    };
  };
}
