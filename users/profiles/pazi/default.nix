{ pkgs, ... }: {
  programs.pazi = {
    enable = true;
    enableFishIntegration = true;    
    };
}
