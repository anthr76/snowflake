{...}: {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    settings = {aliases = {pv = "pr view";};};
  };
}
