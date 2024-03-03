{
  pkgs,
  ...
}:
{
  imports = [
    ../../personalities/base/podman.nix
  ];
  users.users = {
      wolf = {
      isNormalUser = true;
      initialPassword = "wolf";
      linger = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "input"
      ];
    };
  };
  virtualisation.containers.cdi.dynamic.nvidia.enable = true;
  virtualisation.podman.enableNvidia = true;
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
  virtualisation.oci-containers.containers.wolf = {
    autoStart = true;
    image = "ghcr.io/games-on-whales/wolf:stable";
    volumes = [
    "/dev/input:/dev/input"
    "/run/udev:/run/udev"
    "/data/wolf/cfg:/data/wolf/cfg"
    "/data/wolf/apps:/data/wolf/apps"
    "/data/wolf/sockets:/data/wolf/sockets"
    "/run/podman/podman.sock:/var/run/docker.sock"
    ];
    environment = {
      WOLF_STOP_CONTAINER_ON_EXIT = "true";
      WOLF_LOG_LEVEL = "INFO";
      HOST_APPS_STATE_FOLDER = "/data/wolf";
      XDG_RUNTIME_DIR = "/data/wolf/sockets";
      GST_DEBUG= "2";
      WOLF_CFG_FILE = "/data/wolf/cfg/config.toml";
      WOLF_PRIVATE_KEY_FILE = "/data/wolf/cfg/key.pem";
      WOLF_PRIVATE_CERT_FILE = "/data/wolf/cfg/cert.pem";
    };
    extraOptions = [
      "--network=host"
      "--ipc=host"
      "--device-cgroup-rule=c 13:* rmw"
      "--cap-add=CAP_SYS_PTRACE"
      "--cap-add=CAP_NET_ADMIN"
      # TODO: Enable when supported
      "--device=nvidia.com/gpu=all"
    ];
  };
  networking.firewall = {
    allowedTCPPorts = [
      47984
      47989
      48010
    ];
    allowedUDPPorts = [
      47999
      47998
      48000
      48010
    ];
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
