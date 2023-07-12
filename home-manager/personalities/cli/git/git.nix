{
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
      init.defaultBranch = "main";
      gpg.format = "ssh";
      gpg.ssh.defaultKeyCommand = "sh -c 'echo key::$(ssh-add -L | grep -m 1 -E \"pkcs11|Authentication\")";
    };
  };
}
