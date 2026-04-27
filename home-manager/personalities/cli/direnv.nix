{config, pkgs, ...}: {
  programs.direnv = {
    enable = true;
    package = pkgs.stable.direnv;
    config.whitelist.prefix = ["${config.home.homeDirectory}/dev"];
    config.load_dotenv = true;
    config.warn_timeout = 0;
    nix-direnv.enable = true;
  };

  programs.direnv-instant.enable = true;
}
