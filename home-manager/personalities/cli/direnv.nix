{config, ...}:{
    programs.direnv = {
      enable = true;
      whitelist.prefix = [ "${config.home.homeDirectory}/dev" ];
      config.warn_timeout = 0;
    };
    programs.direnv.nix-direnv.enable = true;
}