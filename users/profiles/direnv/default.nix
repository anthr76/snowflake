{
  programs.direnv = {
    # Use nix.
    enable = true;
    enableFishIntegration = true;
    nix-direnv = { 
      enable = true;
      enableFlakes = true;
      };
  };
}
