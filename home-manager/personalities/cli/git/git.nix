{pkgs, ...}:
let
  git-ssh-signingkey = pkgs.writeShellScriptBin "git-ssh-signingkey" ''
    echo key::$(${pkgs.openssh}/bin/ssh-add -L | ${pkgs.gnugrep}/bin/grep -m 1 -E "pkcs11|Authentication")
  '';
in
{
  home.packages = with pkgs; [
    git-ssh-signingkey
  ];
  # TODO: This needs to be modularized..
  programs.git = {
    enable = true;
    userName = "Anthony Rabbito";
    userEmail = "hello@anthonyrabbito.com";
    delta.enable = true;
    # error: The option `programs.git.signing.key' is used but not defined. Issa bug
    # signing.signByDefault = true;
    ignores = [ ".direnv" "result" ];
    extraConfig = {
      commit.gpgsign = true;
      tag.forceSignAnnotated = true;
      tag.gpgsign = true;
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg.ssh.defaultKeyCommand = "git-ssh-signingkey";
    };
  };
}
