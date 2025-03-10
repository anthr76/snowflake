{ pkgs, ... }: {
  home.packages = with pkgs; [ skopeo ];
  home.sessionVariables = {
    DOCKER_HOST = "unix://$(${pkgs.podman}/bin/podman system info -f json | ${pkgs.jq}/bin/jq -r .host.remoteSocket.path)";
  };
  xdg.configFile = {
    registries = {
      target = "containers/registries.conf.d/001-home-manager.conf";
      text = ''
        # Managed with Home Manager
        unqualified-search-registries = ["docker.io"]
        # Development registry
        [[registry]]
        location = "localhost:5005"
        insecure = true
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
