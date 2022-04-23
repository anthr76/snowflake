{
  programs.direnv = {
    # Use nix.
    enable = false;
    enableFishIntegration = true;
    nix-direnv = { enable = true; };
  };
}
