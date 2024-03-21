{inputs, pkgs, ...}:
{
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    package = pkgs.unstable.gamescope;
  };
  environment.systemPackages = [pkgs.unstable.gamescope-wsi];
}
