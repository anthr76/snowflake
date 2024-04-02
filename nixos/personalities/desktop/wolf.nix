{ pkgs, ... }: {
  imports = [
    # TODO: Restore when Podman works
    # ../../personalities/base/podman.nix
  ];
  users.users = {
    wolf = {
      isNormalUser = true;
      initialPassword = "wolf";
      linger = true;
      extraGroups = [ "wheel" "networkmanager" "input" ];
    };
  };
  services.udev.extraRules = ''
    # Allows Wolf to acces /dev/uinput
    KERNEL=="uinput", SUBSYSTEM=="misc", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
    # Move virtual keyboard and mouse into a different seat
    SUBSYSTEMS=="input", ATTRS{id/vendor}=="ab00", MODE="0660", GROUP="input", ENV{ID_SEAT}="seat9"
    # Joypads
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf X-Box One (virtual) pad", MODE="0660", GROUP="input"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf PS5 (virtual) pad", MODE="0660", GROUP="input"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf gamepad (virtual) motion sensors", MODE="0660", GROUP="input"
    SUBSYSTEMS=="input", ATTRS{name}=="Wolf Nintendo (virtual) pad", MODE="0660", GROUP="input"
  '';
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.containers.wolf = {
    autoStart = true;
    image = "ghcr.io/games-on-whales/wolf:sha-b9b9de3";
    volumes = [
      "/dev/input:/dev/input:rw"
      "/run/udev:/run/udev:rw"
      "/data/wolf:/data/wolf:rw"
      # TODO: Restore when podman works.
      # "/run/podman/podman.sock:/run/podman/podman.sock:rw"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
    environment = {
      WOLF_LOG_LEVEL = "INFO";
      HOST_APPS_STATE_FOLDER = "/data/wolf";
      XDG_RUNTIME_DIR = "/data/wolf/sockets";
      WOLF_CFG_FILE = "/data/wolf/cfg/config.toml";
      WOLF_PRIVATE_KEY_FILE = "/data/wolf/cfg/key.pem";
      WOLF_PRIVATE_CERT_FILE = "/data/wolf/cfg/cert.pem";
      # TODO: Restore when Podman works
      # WOLF_DOCKER_SOCKET = "/run/podman/podman.sock";
      WOLF_DOCKER_SOCKET = "/var/run/docker.sock";
    };
    extraOptions = [
      "--network=host"
      "--ipc=host"
      "--device-cgroup-rule=c 13:* rmw"
      "--cap-add=CAP_SYS_PTRACE"
      "--cap-add=CAP_NET_ADMIN"
      "--device=/dev/dri:/dev/dri"
      "--device=/dev/uinput:/dev/uinput"
    ];
  };
  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 48010 ];
    allowedUDPPorts = [ 47999 47998 48000 48010 ];
    allowedUDPPortRanges = [
      {
        from = 48100;
        to = 48110;
      }
      {
        from = 48200;
        to = 48210;
      }
    ];
  };
}
