{ pkgs, ... }: {
  home.packages = with pkgs; [ skopeo ];
  xdg.configFile = {
    registries = {
      target = "containers/registries.conf.d/001-home-manager.conf";
      text = ''
        # Managed with Home Manager
        unqualified-search-registries = ["docker.io"]
      '';
    };
    containers = {
      target = "containers/containers.conf.d/001-home-manager.conf";
      text = ''
        # Managed with Home Manager
        [containers]
        pids_limit = 0
      '';
    };
  };
}
