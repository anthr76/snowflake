{
  # TODO: This needs to be modularized..
  programs.git = {
    enable = true;
    userName = "Anthony Rabbito";
    userEmail = "hello@anthonyrabbito.com";
    delta.enable = true;
    signing.key = "~/.ssh/e39_tpm2.pub";
    signing.signByDefault = true;
    ignores = [ ".direnv" "result" ];
    extraConfig = {
      init.defaultBranch = "main";
      gpg.format = "ssh";
    };
  };
}
