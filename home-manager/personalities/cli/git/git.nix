{pkgs, ...}: let
  git-ssh-signingkey = pkgs.writeShellScriptBin "git-ssh-signingkey" ''
    echo key::$(${pkgs.openssh}/bin/ssh-add -L | ${pkgs.gnugrep}/bin/grep -m 1 -E "pkcs11|Authentication|nistp256")
  '';
in {
  home.packages = with pkgs; [git-ssh-signingkey git-extras pre-commit lazygit];
  catppuccin.delta.enable = true;
  catppuccin.lazygit.enable = true;
  programs.delta = {
    enableGitIntegration = true;
  };
  # TODO: This needs to be modularized..
  programs.git = {
    enable = true;
    # error: The option `programs.git.signing.key' is used but not defined. Issa bug
    # signing.signByDefault = true;
    ignores = [".direnv" "result" ".claude"];
    settings = {
      user = {
        name = "Anthony Rabbito";
        email = "hello@anthonyrabbito.com";
      };
      commit.gpgsign = true;
      tag.forceSignAnnotated = true;
      tag.gpgsign = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg.ssh.defaultKeyCommand = "git-ssh-signingkey";
      url = {
        "ssh://git@github.com" = {insteadOf = "https://github.com";};
        "ssh://git@hf.co" = {insteadOf = "https://huggingface.co";};
      };
    };
  };
}
