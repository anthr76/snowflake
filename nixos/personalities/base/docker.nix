{config, ...}: {
  virtualisation = {
    docker = {
      enable = true;
      # This still is worse then podman.
      rootless.enable = false;
    };
  };
  networking.firewall.trustedInterfaces =
    if config.virtualisation.docker.enable
    then ["docker0"]
    else [];
}
