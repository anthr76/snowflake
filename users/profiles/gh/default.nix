{pkgs, lib, ...}: {
  programs.gh = {
    enable = true;
    enableGitCredentialHelper = false;
    settings = {
      aliases = {
        pv = "pr view";
      };
    };
  };
}
