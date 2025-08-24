{
  virtualisation = {
    docker = {
      enable = true;
      # This still is worse then podman.
      rootless.enable = false;
    };
  };
}
