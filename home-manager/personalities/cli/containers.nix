{
  xdg.configFile = {
    registries = {
      target = "containers/registries.conf.d/001-home-manager.conf";
      text = ''
        # Managed with Home Manager
        unqualified-search-registries = ["registry.fedoraproject.org", "registry.access.redhat.com", "quay.io", "registry.redhat.io", "docker.io"]
      '';
    };
  };
}