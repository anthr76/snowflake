{config, ...}: {
  programs.direnv = {
    enable = true;
    config.whitelist.prefix = ["${config.home.homeDirectory}/dev"];
    config.load_dotenv = true;
    config.warn_timeout = 0;
  };
  programs.direnv.nix-direnv.enable = true;
}
